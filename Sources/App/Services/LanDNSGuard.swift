import Foundation
import Darwin
import MuPiBoxCore

/// Resolves a MuPiBox host to the literal address `MuPiBoxAPIClient` should actually connect to,
/// mirroring Android's `LanOnlyDns`. A saved box's host already passed `LocalEndpointValidator`
/// at add/edit time (e.g. "mupibox.local" or a bare local hostname looks LAN-shaped), but that
/// says nothing about what a live DNS resolution returns - without this, a compromised or
/// malicious DNS answer could rebind that hostname to a public address after the fact. A literal
/// IP address needs no resolution and is validated as-is.
///
/// Lives in the App target (not MuPiBoxCore) because it needs OS-level name resolution
/// (`getaddrinfo`), which is out of scope for Core's Linux-testable, platform-neutral layer.
enum LanDNSGuard {
    enum GuardError: Error, LocalizedError {
        case resolutionFailed
        case noLanAddress

        var errorDescription: String? {
            switch self {
            case .resolutionFailed:
                return "Hostname konnte nicht aufgelöst werden."
            case .noLanAddress:
                return "Der aufgelöste Name zeigt nicht auf ein lokales Netzwerkziel."
            }
        }
    }

    /// Matches `MuPiBoxAPIClient.HostResolver`.
    static func resolve(_ host: String) async throws -> String {
        if isNumericAddress(host) {
            guard LocalEndpointValidator.isLanHost(host) else { throw GuardError.noLanAddress }
            return host
        }
        return try await Task.detached(priority: .userInitiated) {
            try resolveToLanAddress(host: host)
        }.value
    }

    private static func isNumericAddress(_ host: String) -> Bool {
        var ipv4 = in_addr()
        var ipv6 = in6_addr()
        return host.withCString { cString in
            inet_pton(AF_INET, cString, &ipv4) == 1 || inet_pton(AF_INET6, cString, &ipv6) == 1
        }
    }

    private static func resolveToLanAddress(host: String) throws -> String {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var resultPointer: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, &hints, &resultPointer)
        guard status == 0, let first = resultPointer else {
            throw GuardError.resolutionFailed
        }
        defer { freeaddrinfo(first) }

        var current: UnsafeMutablePointer<addrinfo>? = first
        while let info = current {
            if let address = numericString(for: info.pointee), LocalEndpointValidator.isLanHost(address) {
                return address
            }
            current = info.pointee.ai_next
        }
        throw GuardError.noLanAddress
    }

    private static func numericString(for info: addrinfo) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = getnameinfo(
            info.ai_addr,
            info.ai_addrlen,
            &buffer,
            socklen_t(buffer.count),
            nil,
            0,
            NI_NUMERICHOST
        )
        guard status == 0 else { return nil }
        return String(cString: buffer)
    }
}
