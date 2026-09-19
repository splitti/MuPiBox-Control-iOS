import Foundation

public enum LocalEndpointValidator {
    public enum ValidationError: Error, Equatable, LocalizedError, Sendable {
        case emptyHost
        case invalidPort
        case notLanHost

        public var errorDescription: String? {
            switch self {
            case .emptyHost:
                return "Host darf nicht leer sein."
            case .invalidPort:
                return "Ungültiger Port."
            case .notLanHost:
                return "Nur lokale MuPiBox-Ziele sind erlaubt (private IP, .local, .home.arpa oder lokaler Hostname)."
            }
        }
    }

    /// Mirrors the Android `LocalEndpointValidator`: only LAN-shaped hosts may be saved as a
    /// MuPiBox endpoint, so the iOS app never sends TTS text or credentials to an arbitrary
    /// Internet host.
    public static func validate(_ box: BoxEndpoint) throws -> BoxEndpoint {
        var host = box.host.trimmingCharacters(in: .whitespacesAndNewlines)
        if host.hasPrefix("[") && host.hasSuffix("]") {
            host = String(host.dropFirst().dropLast())
        }
        guard !host.isEmpty else { throw ValidationError.emptyHost }
        guard (1...65535).contains(box.port) else { throw ValidationError.invalidPort }
        guard isLanHost(host) else { throw ValidationError.notLanHost }
        var normalized = box
        normalized.host = host
        return normalized
    }

    static func isLanHost(_ host: String) -> Bool {
        let h = host.lowercased()
        if h == "localhost" || h.hasSuffix(".local") || h.hasSuffix(".home.arpa") { return true }
        if !h.contains(".") && !h.contains(":") { return true } // local DNS single-label name
        if isPrivateIPv4(h) { return true }
        if h.contains(":") && (h == "::1" || h.hasPrefix("fe80:") || h.hasPrefix("fc") || h.hasPrefix("fd")) { return true }
        return false
    }

    private static func isPrivateIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        let octets = parts.compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) else { return false }
        switch octets[0] {
        case 10, 127:
            return true
        case 169:
            return octets[1] == 254
        case 172:
            return (16...31).contains(octets[1])
        case 192:
            return octets[1] == 168
        default:
            return false
        }
    }
}
