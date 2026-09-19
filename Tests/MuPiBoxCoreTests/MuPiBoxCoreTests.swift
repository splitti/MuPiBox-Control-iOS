import Foundation
import Testing
@testable import MuPiBoxCore

@Test func boxBuildsExpectedBaseURL() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "192.168.2.114", port: 8090)
    #expect(box.baseURL?.absoluteString == "http://192.168.2.114:8090")
}

@Test func decodesSystemStatus() throws {
    let data = Data(#"{"online":true,"wifi":{"connected":true,"interface":"wlan0","signal_dbm":-48,"quality_percent":81},"battery":{"available":true,"percent":72,"charging":true}}"#.utf8)
    let value = try JSONDecoder().decode(SystemStatus.self, from: data)
    #expect(value.online)
    #expect(value.wifi.qualityPercent == 81)
    #expect(value.battery.percent == 72)
    #expect(value.battery.charging == true)
}

@Test func decodesSpotifyStatus() throws {
    let data = Data(#"{"connected":true,"playing":true,"paused":false,"buffering":false,"volume":32000,"volume_steps":65535,"track":{"name":"Test","artists":["Artist"],"album":"Album","position_ms":1200,"duration_ms":180000}}"#.utf8)
    let value = try JSONDecoder().decode(SpotifyStatus.self, from: data)
    #expect(value.connected)
    #expect(value.track?.name == "Test")
    #expect(value.track?.artists == ["Artist"])
}

// MARK: - LocalEndpointValidator

@Test func acceptsPrivateIPv4() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "192.168.2.114", port: 8090)
    #expect(throws: Never.self) { try LocalEndpointValidator.validate(box) }
}

@Test func acceptsDotLocalHostname() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "mupibox.local", port: 8090)
    #expect(throws: Never.self) { try LocalEndpointValidator.validate(box) }
}

@Test func acceptsSingleLabelLanHostname() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "mupibox", port: 8090)
    #expect(throws: Never.self) { try LocalEndpointValidator.validate(box) }
}

@Test func rejectsPublicIPv4() throws {
    let box = BoxEndpoint(name: "Fremd", host: "8.8.8.8", port: 8090)
    #expect(throws: LocalEndpointValidator.ValidationError.notLanHost) {
        try LocalEndpointValidator.validate(box)
    }
}

@Test func rejectsPublicHostname() throws {
    let box = BoxEndpoint(name: "Fremd", host: "example.com", port: 8090)
    #expect(throws: LocalEndpointValidator.ValidationError.notLanHost) {
        try LocalEndpointValidator.validate(box)
    }
}

@Test func rejectsInvalidPort() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "192.168.2.114", port: 0)
    #expect(throws: LocalEndpointValidator.ValidationError.invalidPort) {
        try LocalEndpointValidator.validate(box)
    }
}

@Test func rejectsEmptyHost() throws {
    let box = BoxEndpoint(name: "Kinderzimmer", host: "   ", port: 8090)
    #expect(throws: LocalEndpointValidator.ValidationError.emptyHost) {
        try LocalEndpointValidator.validate(box)
    }
}

// MARK: - PlaybackSourceSelector

private func player(state: String, queueCount: Int) throws -> PlayerStatus {
    let queueJSON = queueCount > 0 ? #"[{"id":"1","title":"Titel"}]"# : "[]"
    let json = #"{"state":"\#(state)","backend":"mpv","folder_id":"","folder":"","queue":\#(queueJSON),"index":0,"position":0,"duration":0,"volume":10,"max_volume":50}"#
    return try JSONDecoder().decode(PlayerStatus.self, from: Data(json.utf8))
}

private func spotify(playing: Bool, paused: Bool, hasTrack: Bool) throws -> SpotifyStatus {
    let trackJSON = hasTrack
        ? #","track":{"name":"Song","artists":["Artist"],"album":"Album","position_ms":0,"duration_ms":0}"#
        : ""
    let json = #"{"connected":true,"playing":\#(playing),"paused":\#(paused),"buffering":false,"volume":100,"volume_steps":200\#(trackJSON)}"#
    return try JSONDecoder().decode(SpotifyStatus.self, from: Data(json.utf8))
}

@Test func sourceIsLocalWhenOnlyLocalHasSession() throws {
    let source = PlaybackSourceSelector.active(
        player: try player(state: "playing", queueCount: 1),
        spotify: try spotify(playing: false, paused: false, hasTrack: false)
    )
    #expect(source == .local)
}

@Test func sourceIsSpotifyOnlyWhenLocalHasNoSession() throws {
    let source = PlaybackSourceSelector.active(
        player: try player(state: "stopped", queueCount: 0),
        spotify: try spotify(playing: true, paused: false, hasTrack: true)
    )
    #expect(source == .spotify)
}

@Test func sourceStaysLocalWhenBothHaveASession() throws {
    let source = PlaybackSourceSelector.active(
        player: try player(state: "playing", queueCount: 1),
        spotify: try spotify(playing: true, paused: false, hasTrack: true)
    )
    #expect(source == .local)
}

@Test func sourceIsLocalWhenNeitherHasASession() throws {
    let source = PlaybackSourceSelector.active(player: nil, spotify: nil)
    #expect(source == .local)
}

// MARK: - VolumeScaling

@Test func volumePercentFromLocalMaxVolume() throws {
    #expect(VolumeScaling.percent(raw: 25, max: 50) == 50)
}

@Test func volumePercentFromSpotifyVolumeSteps() throws {
    #expect(VolumeScaling.percent(raw: 32768, max: 65535) == 50)
}

@Test func volumePercentClampsToHundred() throws {
    #expect(VolumeScaling.percent(raw: 999, max: 50) == 100)
}

@Test func volumePercentIsZeroWhenMaxIsZero() throws {
    #expect(VolumeScaling.percent(raw: 10, max: 0) == 0)
}

@Test func rawVolumeFromPercentRoundTripsForLocal() throws {
    #expect(VolumeScaling.raw(percent: 50, max: 50) == 25)
}

@Test func rawVolumeFromPercentClampsToMax() throws {
    #expect(VolumeScaling.raw(percent: 150, max: 50) == 50)
}
