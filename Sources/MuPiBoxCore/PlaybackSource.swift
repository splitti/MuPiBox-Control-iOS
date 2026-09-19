import Foundation

public enum PlaybackSource: Equatable, Sendable {
    case local
    case spotify
}

public enum PlaybackSourceSelector {
    /// Mirrors the Android `PlaybackSourceSelector`: Spotify is only considered the active
    /// source when it has a session and local playback does not. This keeps the "what is
    /// currently playing" rule identical on both platforms instead of favoring Spotify
    /// whenever it merely reports `connected`.
    public static func active(player: PlayerStatus?, spotify: SpotifyStatus?) -> PlaybackSource {
        let localHasSession = (player?.queue.isEmpty == false) && (player?.state == "playing" || player?.state == "paused")
        let spotifyHasSession = (spotify?.track != nil) && (spotify?.playing == true || spotify?.paused == true)
        return (spotifyHasSession && !localHasSession) ? .spotify : .local
    }
}
