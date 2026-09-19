import SwiftUI
import MuPiBoxCore

struct DashboardView: View {
    @Bindable var model: AppModel
    @State private var showingAddBox = false
    @State private var showingBoxes = false
    @State private var showingBluetooth = false
    @State private var ttsText = ""

    var body: some View {
        NavigationStack {
            Group {
                if model.selectedBox == nil {
                    ContentUnavailableView {
                        Label("Keine MuPiBox", systemImage: "hifispeaker")
                    } description: {
                        Text("Füge eine Box per Hostname oder lokaler IP-Adresse hinzu.")
                    } actions: {
                        Button("MuPiBox hinzufügen") { showingAddBox = true }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: DesignTokens.sectionSpacing) {
                            connectionHeader
                            statusCards
                            nowPlayingCard
                            transportCard
                            ttsCard
                        }
                        .padding(DesignTokens.pagePadding)
                    }
                    .refreshable { await model.refresh() }
                }
            }
            .navigationTitle("MuPiBox Control")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingBoxes = true
                    } label: {
                        Label(model.selectedBox?.name ?? "Box", systemImage: "hifispeaker")
                    }
                }
            }
            .sheet(isPresented: $showingBoxes) {
                BoxesView(model: model)
            }
            .sheet(isPresented: $showingAddBox) {
                AddBoxView(model: model)
            }
            .sheet(isPresented: $showingBluetooth) {
                BluetoothView(model: model)
            }
            .alert("Verbindungsfehler", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "Unbekannter Fehler")
            }
        }
    }

    private var connectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.selectedBox?.name ?? "MuPiBox")
                    .font(.headline)
                if let box = model.selectedBox {
                    Text("\(box.host):\(box.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Label(model.health?.status == "ok" ? "Online" : "Offline",
                  systemImage: model.health?.status == "ok" ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.subheadline.weight(.semibold))
        }
        .cardStyle()
    }

    private var nowPlayingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aktuelle Wiedergabe")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if isSpotifyActive, let spotify = model.spotify, let track = spotify.track {
                Text(track.name).font(.title3.weight(.semibold))
                Text(track.artists.joined(separator: ", "))
                    .foregroundStyle(.secondary)
                Label("Spotify", systemImage: "music.note")
                    .font(.caption)
            } else if let track = model.player?.currentTrack {
                Text(track.title ?? model.player?.folder ?? "Lokale Medien")
                    .font(.title3.weight(.semibold))
                Text(model.player?.folder ?? "Lokale Medien")
                    .foregroundStyle(.secondary)
                Label("Lokale Wiedergabe", systemImage: "internaldrive")
                    .font(.caption)
            } else {
                Text("Keine Wiedergabe")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var transportCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                Button { Task { await previous() } } label: {
                    Image(systemName: "backward.fill")
                }
                .controlButton()

                Button { Task { await togglePlayback() } } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                .controlButton(primary: true)

                Button { Task { await next() } } label: {
                    Image(systemName: "forward.fill")
                }
                .controlButton()
            }

            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: volumePercentBinding, in: 0...100, step: 1)
                Image(systemName: "speaker.wave.3.fill")
            }
            Text("Lautstärke \(model.volumePercent) %")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var statusCards: some View {
        HStack(spacing: 12) {
            statusCard(
                title: "Akku",
                value: batteryText,
                icon: model.system?.battery.charging == true ? "battery.100percent.bolt" : "battery.75percent"
            )
            statusCard(
                title: "WLAN",
                value: wifiText,
                icon: model.system?.wifi.connected == true ? "wifi" : "wifi.slash"
            )
            Button {
                showingBluetooth = true
                Task { await model.scanBluetooth() }
            } label: {
                statusCard(title: "Bluetooth", value: "Anzeigen", icon: "bluetooth")
            }
            .buttonStyle(.plain)
        }
    }

    private var ttsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text an die Box")
                .font(.headline)
            TextField("Text, den die MuPiBox sprechen soll", text: $ttsText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)
            Button {
                let text = ttsText
                Task {
                    await model.speak(text)
                    if model.errorMessage == nil { ttsText = "" }
                }
            } label: {
                if model.isSpeaking {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Label("Vorlesen", systemImage: "waveform")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(ttsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isSpeaking)
        }
        .cardStyle()
    }

    private func statusCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption.weight(.semibold))
            Text(value).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .cardStyle()
    }

    private var isSpotifyActive: Bool {
        model.activeSource == .spotify
    }

    private var isPlaying: Bool {
        isSpotifyActive ? (model.spotify?.playing == true) : (model.player?.state == "playing")
    }

    private var volumePercentBinding: Binding<Double> {
        Binding(
            get: { Double(model.volumePercent) },
            set: { newValue in
                Task { await model.setVolumePercent(Int(newValue.rounded())) }
            }
        )
    }

    private var batteryText: String {
        guard let battery = model.system?.battery, battery.available else { return "Unbekannt" }
        return battery.percent.map { "\($0)%" } ?? "Verfügbar"
    }

    private var wifiText: String {
        guard let wifi = model.system?.wifi, wifi.connected else { return "Offline" }
        return wifi.qualityPercent.map { "\($0)%" } ?? (wifi.interface ?? "Online")
    }

    private func togglePlayback() async {
        if isSpotifyActive {
            await model.spotifyCommand(model.spotify?.playing == true ? "pause" : "resume")
        } else {
            await model.localCommand(model.player?.state == "playing" ? "pause" : "play")
        }
    }

    private func previous() async {
        if isSpotifyActive { await model.spotifyCommand("previous") }
        else { await model.localCommand("previous") }
    }

    private func next() async {
        if isSpotifyActive { await model.spotifyCommand("next") }
        else { await model.localCommand("next") }
    }
}

private enum DesignTokens {
    static let pagePadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let cardRadius: CGFloat = 20
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
    }

    func controlButton(primary: Bool = false) -> some View {
        self
            .font(primary ? .title : .title2)
            .frame(width: primary ? 68 : 52, height: primary ? 68 : 52)
            .background(primary ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
            .foregroundStyle(primary ? Color.white : Color.primary)
            .buttonStyle(.plain)
    }
}
