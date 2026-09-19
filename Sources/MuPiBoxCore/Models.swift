import Foundation

public struct BoxEndpoint: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var host: String
    public var port: Int

    public init(id: UUID = UUID(), name: String, host: String, port: Int = 8090) {
        self.id = id
        self.name = name
        self.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        self.port = port
    }

    public var baseURL: URL? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = port
        return components.url
    }
}

public struct HealthResponse: Codable, Equatable, Sendable {
    public let status: String
    public let version: String
}

public struct SystemStatus: Codable, Equatable, Sendable {
    public let online: Bool
    public let wifi: WiFiStatus
    public let battery: BatteryStatus
}

public struct WiFiStatus: Codable, Equatable, Sendable {
    public let connected: Bool
    public let interface: String?
    public let signalDBM: Int?
    public let qualityPercent: Int?

    enum CodingKeys: String, CodingKey {
        case connected
        case interface
        case signalDBM = "signal_dbm"
        case qualityPercent = "quality_percent"
    }
}

public struct BatteryStatus: Codable, Equatable, Sendable {
    public let available: Bool
    public let percent: Int?
    public let charging: Bool?
}

public struct LibraryTrack: Codable, Equatable, Sendable {
    public let id: String?
    public let title: String?
    public let artist: String?
    public let album: String?
    public let path: String?
}

public struct PlayerStatus: Codable, Equatable, Sendable {
    public let state: String
    public let backend: String
    public let folderID: String
    public let folder: String
    public let cover: String?
    public let queue: [LibraryTrack]
    public let index: Int
    public let position: Double
    public let duration: Double
    public let volume: Int
    public let maxVolume: Int
    public let error: String?

    enum CodingKeys: String, CodingKey {
        case state, backend, folder, cover, queue, index, position, duration, volume, error
        case folderID = "folder_id"
        case maxVolume = "max_volume"
    }

    public var currentTrack: LibraryTrack? {
        guard queue.indices.contains(index) else { return nil }
        return queue[index]
    }
}

public struct SpotifyStatus: Codable, Equatable, Sendable {
    public let connected: Bool
    public let playing: Bool
    public let paused: Bool
    public let buffering: Bool
    public let volume: Int
    public let volumeSteps: Int
    public let track: SpotifyTrack?

    enum CodingKeys: String, CodingKey {
        case connected, playing, paused, buffering, volume, track
        case volumeSteps = "volume_steps"
    }
}

public struct SpotifyTrack: Codable, Equatable, Sendable {
    public let name: String
    public let artists: [String]
    public let album: String
    public let cover: String?
    public let positionMS: Int64
    public let durationMS: Int64

    enum CodingKeys: String, CodingKey {
        case name, artists, album, cover
        case positionMS = "position_ms"
        case durationMS = "duration_ms"
    }
}

public struct BluetoothScanResponse: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let devices: [BluetoothDevice]
}

public struct BluetoothDevice: Codable, Equatable, Identifiable, Sendable {
    public var id: String { address }
    public let address: String
    public let name: String?
    public let paired: Bool?
    public let trusted: Bool?
    public let connected: Bool?
}
