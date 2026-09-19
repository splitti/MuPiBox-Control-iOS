import Foundation
import Network

@MainActor
final class BonjourDiscovery: ObservableObject {
    @Published private(set) var endpoints: [NWEndpoint] = []
    private var browser: NWBrowser?

    func start() {
        guard browser == nil else { return }
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_mupibox._tcp", domain: nil), using: parameters)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.endpoints = results.map(\.endpoint)
            }
        }
        browser.stateUpdateHandler = { _ in }
        browser.start(queue: .main)
        self.browser = browser
    }

    func stop() {
        browser?.cancel()
        browser = nil
        endpoints = []
    }
}
