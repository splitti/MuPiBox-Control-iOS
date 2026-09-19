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
