import SwiftUI

@main
struct MuPiBoxControlApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(model: model)
                .task { await model.start() }
        }
    }
}
