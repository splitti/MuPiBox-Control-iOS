import Foundation

/// Converts between the MuPiBox API's raw volume ranges (local `0...max_volume`, Spotify
/// `0...volume_steps`) and the normalized 0–100 % the UI always presents, matching the Android
/// `ControlRepository`/`BoxControlUiState` rule. The UI must never show a raw value such as a
/// Spotify `volume_steps` of 65535 directly.
public enum VolumeScaling {
    public static func percent(raw: Int, max: Int) -> Int {
        guard max > 0 else { return 0 }
        let value = (Double(raw) / Double(max) * 100).rounded()
        return Swift.min(Swift.max(Int(value), 0), 100)
    }

    public static func raw(percent: Int, max: Int) -> Int {
        let clampedPercent = Swift.min(Swift.max(percent, 0), 100)
        guard max > 0 else { return 0 }
        let value = (Double(clampedPercent) / 100.0 * Double(max)).rounded()
        return Swift.min(Swift.max(Int(value), 0), max)
    }
}
