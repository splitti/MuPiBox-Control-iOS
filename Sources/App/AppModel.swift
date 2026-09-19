import Foundation
import Observation
import MuPiBoxCore

@MainActor
@Observable
final class AppModel {
    var boxes: [BoxEndpoint] = []
    var selectedBoxID: UUID?
    var health: HealthResponse?
    var player: PlayerStatus?
    var system: SystemStatus?
    var spotify: SpotifyStatus?
    var bluetoothDevices: [BluetoothDevice] = []
    /// Per-box reachability for the box list, keyed by id; nil = not yet checked. Matches
    /// Android's `BoxesViewModel.refreshOnlineStates` - cheap enough to call every time the list
    /// is shown, unlike the Bluetooth scan endpoint.
    var onlineStates: [UUID: Bool] = [:]
    var errorMessage: String?
    var isRefreshing = false
    var isSpeaking = false
    var isScanningBluetooth = false

    private let api = MuPiBoxAPIClient(resolveHost: LanDNSGuard.resolve)
    private let defaultsKey = "mupibox.control.boxes.v1"
    private let selectionKey = "mupibox.control.selectedBox.v1"
    private var fastRefreshTask: Task<Void, Never>?
    private var slowRefreshTask: Task<Void, Never>?

    var selectedBox: BoxEndpoint? {
        guard let selectedBoxID else { return boxes.first }
        return boxes.first(where: { $0.id == selectedBoxID }) ?? boxes.first
    }

    /// Matches the Android control screen: local/Spotify playback state is derived with the
    /// same rule on both platforms instead of each app guessing independently.
    var activeSource: PlaybackSource {
        PlaybackSourceSelector.active(player: player, spotify: spotify)
    }

    /// Volume normalized to 0–100 %, matching the Android control screen. Never expose the raw
    /// local `max_volume` or Spotify `volume_steps` range in the UI.
    var volumePercent: Int {
        switch activeSource {
        case .spotify:
            return VolumeScaling.percent(raw: spotify?.volume ?? 0, max: spotify?.volumeSteps ?? 0)
        case .local:
            return VolumeScaling.percent(raw: player?.volume ?? 0, max: player?.maxVolume ?? 0)
        }
    }

    func setVolumePercent(_ percent: Int) async {
        switch activeSource {
        case .spotify:
            let raw = VolumeScaling.raw(percent: percent, max: spotify?.volumeSteps ?? 0)
            await spotifyCommand("volume", value: Int64(raw))
        case .local:
            let raw = VolumeScaling.raw(percent: percent, max: player?.maxVolume ?? 0)
            await localCommand("volume", value: Double(raw))
        }
    }

    func start() async {
        loadBoxes()
        await refresh()
        startPolling()
    }

    func startPolling() {
        stopPolling()
        // Player/Spotify state refreshes at the same ~1 s cadence as the Android control
        // screen; system status (battery/Wi-Fi/health) stays on the cheaper ~5 s cadence.
        fastRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                await self?.refreshPlayback(silent: true)
            }
        }
        slowRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await self?.refreshSystem(silent: true)
            }
        }
    }

    func stopPolling() {
        fastRefreshTask?.cancel()
        fastRefreshTask = nil
        slowRefreshTask?.cancel()
        slowRefreshTask = nil
    }

    /// Validates a candidate against `LocalEndpointValidator` and requires a passing
    /// `/api/health` probe before it may be saved - matches Android's `BoxRepository.add`. Used
    /// by both `addBox` and `updateBox` so add/edit can never diverge on what counts as valid.
    private func validatedAndReachable(_ candidate: BoxEndpoint) async -> BoxEndpoint? {
        let normalized: BoxEndpoint
        do {
            normalized = try LocalEndpointValidator.validate(candidate)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
        do {
            let probeHealth = try await api.health(normalized)
            guard probeHealth.status == "ok" else {
                errorMessage = "Host antwortet, ist aber keine erreichbare MuPiBox."
                return nil
            }
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
        errorMessage = nil
        return normalized
    }

    func addBox(name: String, host: String, port: Int) async {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = BoxEndpoint(name: cleanName.isEmpty ? host : cleanName, host: host, port: port)
        guard let normalized = await validatedAndReachable(candidate) else { return }
        boxes.append(normalized)
        selectedBoxID = normalized.id
        saveBoxes()
        await refresh()
    }

    func updateBox(_ original: BoxEndpoint, name: String, host: String, port: Int) async {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = BoxEndpoint(id: original.id, name: cleanName.isEmpty ? host : cleanName, host: host, port: port)
        guard let normalized = await validatedAndReachable(candidate) else { return }
        guard let index = boxes.firstIndex(where: { $0.id == original.id }) else { return }
        boxes[index] = normalized
        onlineStates[original.id] = nil
        saveBoxes()
        await refresh()
    }

    func removeBox(_ box: BoxEndpoint) async {
        boxes.removeAll { $0.id == box.id }
        onlineStates[box.id] = nil
        if selectedBoxID == box.id { selectedBoxID = boxes.first?.id }
        saveBoxes()
        await refresh()
    }

    func refreshOnlineStates() async {
        for box in boxes {
            Task {
                let reachable = (try? await api.health(box))?.status == "ok"
                onlineStates[box.id] = reachable
            }
        }
    }

    func select(_ box: BoxEndpoint) async {
        selectedBoxID = box.id
        saveBoxes()
        await refresh()
    }

    func refresh(silent: Bool = false) async {
        guard selectedBox != nil else {
            health = nil; player = nil; system = nil; spotify = nil
            return
        }
        if !silent { isRefreshing = true }
        defer { if !silent { isRefreshing = false } }
        async let playbackRefresh: Void = refreshPlayback(silent: true)
        async let systemRefresh: Void = refreshSystem(silent: true)
        _ = await (playbackRefresh, systemRefresh)
    }

    private func refreshPlayback(silent: Bool) async {
        guard let box = selectedBox else { return }
        do {
            async let playerRequest = api.playerStatus(box)
            async let spotifyRequest = api.spotifyStatus(box)
            let (playerValue, spotifyValue) = try await (playerRequest, spotifyRequest)
            player = playerValue
            spotify = spotifyValue
            errorMessage = nil
        } catch {
            if !silent { errorMessage = error.localizedDescription }
        }
    }

    private func refreshSystem(silent: Bool) async {
        guard let box = selectedBox else { return }
        do {
            async let healthRequest = api.health(box)
            async let systemRequest = api.systemStatus(box)
            let (healthValue, systemValue) = try await (healthRequest, systemRequest)
            health = healthValue
            system = systemValue
        } catch {
            if !silent { errorMessage = error.localizedDescription }
        }
    }

    func localCommand(_ action: String, value: Double? = nil) async {
        guard let box = selectedBox else { return }
        do {
            player = try await api.command(box, action: action, value: value)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func spotifyCommand(_ action: String, value: Int64? = nil) async {
        guard let box = selectedBox else { return }
        do {
            spotify = try await api.spotifyCommand(box, action: action, value: value)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func speak(_ text: String) async {
        guard let box = selectedBox else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        isSpeaking = true
        defer { isSpeaking = false }
        do {
            try await api.speak(box, text: clean)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func scanBluetooth() async {
        guard let box = selectedBox else { return }
        isScanningBluetooth = true
        defer { isScanningBluetooth = false }
        do {
            bluetoothDevices = try await api.bluetoothScan(box).devices
            errorMessage = nil
        } catch {
            bluetoothDevices = []
            errorMessage = BluetoothErrorPresentation.message(for: error)
        }
    }

    private func loadBoxes() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([BoxEndpoint].self, from: data) {
            boxes = decoded
        }
        if let raw = UserDefaults.standard.string(forKey: selectionKey) {
            selectedBoxID = UUID(uuidString: raw)
        }
        if selectedBoxID == nil { selectedBoxID = boxes.first?.id }
    }

    private func saveBoxes() {
        if let data = try? JSONEncoder().encode(boxes) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
        UserDefaults.standard.set(selectedBoxID?.uuidString, forKey: selectionKey)
    }
}
