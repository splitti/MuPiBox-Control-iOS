import SwiftUI
import MuPiBoxCore

/// Box list, matching the Android `BoxesScreen` content: title, saved boxes with name and
/// host/IP, and an add-box action. Presented as a sheet rather than Android's full-screen swap —
/// an allowed native navigation difference — but the visible hierarchy and terminology match.
struct BoxesView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddBox = false

    var body: some View {
        NavigationStack {
            Group {
                if model.boxes.isEmpty {
                    ContentUnavailableView {
                        Label("Keine MuPiBox", systemImage: "hifispeaker")
                    } description: {
                        Text("Für den MVP kann eine Box per Hostname oder privater IP hinzugefügt werden.")
                    } actions: {
                        Button("MuPiBox hinzufügen") { showingAddBox = true }
                    }
                } else {
                    List {
                        ForEach(model.boxes) { box in
                            Button {
                                Task {
                                    await model.select(box)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(box.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("\(box.host):\(box.port)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if box.id == model.selectedBox?.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let box = model.boxes[index]
                                Task { await model.removeBox(box) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("MuPiBox Control")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("MuPiBox hinzufügen", systemImage: "plus") { showingAddBox = true }
                }
            }
            .sheet(isPresented: $showingAddBox) {
                AddBoxView(model: model)
            }
        }
    }
}
