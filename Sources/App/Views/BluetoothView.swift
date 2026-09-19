import SwiftUI

struct BluetoothView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.isScanningBluetooth {
                    ProgressView("Bluetooth-Geräte werden gesucht …")
                } else if model.bluetoothDevices.isEmpty {
                    ContentUnavailableView(
                        "Keine Geräte",
                        systemImage: "bluetooth",
                        description: Text("Bluetooth wird nur auf Anforderung gescannt. Ist Bluetooth an der MuPiBox deaktiviert, meldet die Box dies als Fehler.")
                    )
                } else {
                    List(model.bluetoothDevices) { device in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name ?? "Bluetooth-Gerät")
                            Text(device.address)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            HStack {
                                if device.paired == true { Label("Gekoppelt", systemImage: "link") }
                                if device.connected == true { Label("Verbunden", systemImage: "checkmark.circle") }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Bluetooth")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Schließen") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Neu scannen") { Task { await model.scanBluetooth() } }
                        .disabled(model.isScanningBluetooth)
                }
            }
        }
    }
}
