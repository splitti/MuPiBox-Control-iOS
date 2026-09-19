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
    var errorMessage: String?
    var isRefreshing = false
    var isSpeaking = false
    var isScanningBluetooth = false

    private let api = MuPiBoxAPIClient()
    private let defaultsKey = "mupibox.control.boxes.v1"
    private let selectionKey = "mupibox.control.selectedBox.v1"
    private var refreshTask: Task<Void, Never>?

    var selectedBox: BoxEndpoint? {
        guard let selectedBoxID else { return boxes.first }
        return boxes.first(where: { $0.id == selectedBoxID }) ?? boxes.first
    }

    func start() async {
        loadBoxes()
        await refresh()
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await self?.refresh(silent: true)
            }
        }
    }

    func addBox(name: String, host: String, port: Int) async {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanHost.isEmpty, (1...65535).contains(port) else {
            errorMessage = "Bitte Host/IP und einen gültigen Port angeben."
            return
        }
        let box = BoxEndpoint(name: cleanName.isEmpty ? cleanHost : cleanName, host: cleanHost, port: port)
        boxes.append(box)
        selectedBoxID = box.id
        saveBoxes()
        await refresh()
    }

    func removeBox(_ box: BoxEndpoint) async {
        boxes.removeAll { $0.id == box.id }
        if selectedBoxID == box.id { selectedBoxID = boxes.first?.id }
        saveBoxes()
        await refresh()
    }

    func select(_ box: BoxEndpoint) async {
        selectedBoxID = box.id
        saveBoxes()
        await refresh()
    }

    func refresh(silent: Bool = false) async {
        guard let box = selectedBox else {
            health = nil; player = nil; system = nil; spotify = nil
            return
        }
        if !silent { isRefreshing = true }
        defer { if !silent { isRefreshing = false } }
        do {
            async let healthRequest = api.health(box)
            async let playerRequest = api.playerStatus(box)
            async let systemRequest = api.systemStatus(box)
            async let spotifyRequest = api.spotifyStatus(box)
            let values = try await (healthRequest, playerRequest, systemRequest, spotifyRequest)
            health = values.0
            player = values.1
            system = values.2
            spotify = values.3
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
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
