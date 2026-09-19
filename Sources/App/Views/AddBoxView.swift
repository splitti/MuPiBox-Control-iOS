import SwiftUI
import MuPiBoxCore

/// Add or edit a saved MuPiBox. Handles both in one view (rather than a near-duplicate
/// EditBoxView) since the form, validation, and health-check flow are identical - only the
/// title/action label and which AppModel method gets called differ.
struct AddBoxView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let editing: BoxEndpoint?

    @State private var name: String
    @State private var host: String
    @State private var port: String

    init(model: AppModel, editing: BoxEndpoint? = nil) {
        self.model = model
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "MuPiBox")
        _host = State(initialValue: editing?.host ?? "")
        _port = State(initialValue: editing.map { String($0.port) } ?? "8090")
    }

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
            .navigationTitle(editing == nil ? "MuPiBox hinzufügen" : "MuPiBox bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                            if let editing {
                                await model.updateBox(editing, name: name, host: host, port: Int(port) ?? 8090)
                            } else {
                                await model.addBox(name: name, host: host, port: Int(port) ?? 8090)
                            }
                            if model.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
