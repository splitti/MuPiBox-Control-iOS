import SwiftUI

struct AddBoxView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = "MuPiBox"
    @State private var host = ""
    @State private var port = "8090"

    var body: some View {
        NavigationStack {
            Form {
                Section("MuPiBox") {
                    TextField("Name", text: $name)
                    TextField("Hostname oder lokale IP", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                Section {
                    Text("mDNS/Bonjour (_mupibox._tcp) ist vorbereitet. Solange die MuPiBox diesen Dienst nicht veröffentlicht, bleibt Hostname/IP der zuverlässige Weg.")
                        .font(.footnote)
                }
            }
            .navigationTitle("MuPiBox hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            await model.addBox(name: name, host: host, port: Int(port) ?? 8090)
                            if model.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
