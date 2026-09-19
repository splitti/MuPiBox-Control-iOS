import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum MuPiBoxAPIError: Error, Equatable, LocalizedError, Sendable {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int, String?)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Ungültige MuPiBox-Adresse."
        case .invalidResponse:
            return "Ungültige Antwort der MuPiBox."
        case let .httpStatus(code, message):
            return message.map { "MuPiBox antwortet mit HTTP \(code): \($0)" } ?? "MuPiBox antwortet mit HTTP \(code)."
        case let .decoding(message):
            return "Antwort konnte nicht gelesen werden: \(message)"
        }
    }
}

private struct ProblemResponse: Codable {
    let error: String?
}

private struct PlayerCommand: Codable {
    let action: String
    let folderID: String?
    let itemIndex: Int?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case action, value
        case folderID = "folder_id"
        case itemIndex = "item_index"
    }
}

private struct SpotifyCommand: Codable {
    let action: String
    let value: Int64?
}

private struct SpeakRequest: Codable {
    let sourceType: String
    let sourceRef: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case text
        case sourceType = "source_type"
        case sourceRef = "source_ref"
    }
}

public actor MuPiBoxAPIClient {
    /// Resolves `box.host` to the literal address this client should actually connect to.
    /// Mirrors Android's `LanOnlyDns`: a saved box's host already passed `LocalEndpointValidator`
    /// at add time (it *looks* like a LAN target), but that says nothing about what a live DNS
    /// resolution returns - a resolver should re-validate every resolved address is itself a LAN
    /// address before connecting, so a compromised/rebinding DNS answer can't redirect a saved
    /// box to a public host. `MuPiBoxCore` stays Linux-testable and has no OS resolver access, so
    /// this is injected from the App target (see `LanDNSGuard`); without one, `box.host` is used
    /// as-is (this is what every unit test does, since none of them touch the real network).
    public typealias HostResolver = @Sendable (String) async throws -> String

    private let session: URLSession
    private let resolveHost: HostResolver?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(session: URLSession = .shared, resolveHost: HostResolver? = nil) {
        self.session = session
        self.resolveHost = resolveHost
    }

    public func health(_ box: BoxEndpoint) async throws -> HealthResponse {
        try await get(box, path: "/api/health")
    }

    public func playerStatus(_ box: BoxEndpoint) async throws -> PlayerStatus {
        try await get(box, path: "/api/status")
    }

    public func systemStatus(_ box: BoxEndpoint) async throws -> SystemStatus {
        try await get(box, path: "/api/system")
    }

    public func spotifyStatus(_ box: BoxEndpoint) async throws -> SpotifyStatus {
        try await get(box, path: "/api/spotify/status")
    }

    public func bluetoothScan(_ box: BoxEndpoint) async throws -> BluetoothScanResponse {
        try await get(box, path: "/api/connectivity/bluetooth", timeout: 20)
    }

    @discardableResult
    public func command(
        _ box: BoxEndpoint,
        action: String,
        value: Double? = nil,
        folderID: String? = nil,
        itemIndex: Int? = nil
    ) async throws -> PlayerStatus {
        let body = PlayerCommand(action: action, folderID: folderID, itemIndex: itemIndex, value: value)
        return try await send(box, path: "/api/command", method: "POST", body: body)
    }

    @discardableResult
    public func spotifyCommand(_ box: BoxEndpoint, action: String, value: Int64? = nil) async throws -> SpotifyStatus {
        let body = SpotifyCommand(action: action, value: value)
        return try await send(box, path: "/api/spotify/command", method: "POST", body: body)
    }

    public func speak(_ box: BoxEndpoint, text: String) async throws {
        // Matches Android's MuPiBoxClient.speak(): same source_ref, sibling-specific source_type.
        let body = SpeakRequest(sourceType: "ios-app", sourceRef: "mupibox-control", text: text)
        let _: EmptySuccess = try await send(box, path: "/api/speak", method: "POST", body: body, timeout: 25)
    }

    private func get<Response: Decodable>(_ box: BoxEndpoint, path: String, timeout: TimeInterval = 8) async throws -> Response {
        try await request(box, path: path, method: "GET", body: Optional<String>.none, timeout: timeout)
    }

    private func send<Body: Encodable, Response: Decodable>(
        _ box: BoxEndpoint,
        path: String,
        method: String,
        body: Body,
        timeout: TimeInterval = 8
    ) async throws -> Response {
        try await request(box, path: path, method: method, body: body, timeout: timeout)
    }

    private func request<Body: Encodable, Response: Decodable>(
        _ box: BoxEndpoint,
        path: String,
        method: String,
        body: Body?,
        timeout: TimeInterval
    ) async throws -> Response {
        guard let baseURL = box.baseURL else { throw MuPiBoxAPIError.invalidBaseURL }
        var connectURL = baseURL
        if let resolveHost {
            let resolvedHost = try await resolveHost(box.host)
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                throw MuPiBoxAPIError.invalidBaseURL
            }
            components.host = resolvedHost
            guard let resolvedURL = components.url else { throw MuPiBoxAPIError.invalidBaseURL }
            connectURL = resolvedURL
        }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = connectURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MuPiBoxAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = try? decoder.decode(ProblemResponse.self, from: data).error
            throw MuPiBoxAPIError.httpStatus(http.statusCode, message ?? nil)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw MuPiBoxAPIError.decoding(error.localizedDescription)
        }
    }
}

private struct EmptySuccess: Decodable {
    init(from decoder: Decoder) throws {
        _ = try? decoder.singleValueContainer()
    }
}
