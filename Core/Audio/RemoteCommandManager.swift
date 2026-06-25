import MediaPlayer
import Observation

@Observable
final class RemoteCommandManager {
    
    static let shared = RemoteCommandManager()
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingInfo = MPNowPlayingInfoCenter.default()
    
    // Callbacks
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onNextTrack: (() -> Void)?
    var onPreviousTrack: (() -> Void)?
    var onSeek: ((TimeInterval) -> Void)?
    var onChangePlaybackPosition: ((TimeInterval) -> Void)?
    var onLike: (() -> Void)?
    var onDislike: (() -> Void)?
    
    private init() {}
    
    func configure() {
        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onPlay?()
            return .success
        }
        
        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onPause?()
            return .success
        }
        
        // Toggle Play/Pause
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onTogglePlayPause?()
            return .success
        }
        
        // Next Track
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNextTrack?()
            return .success
        }
        
        // Previous Track
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPreviousTrack?()
            return .success
        }
        
        // Seek
        commandCenter.seekForwardCommand.addTarget { [weak self] event in
            guard let seekEvent = event as? MPSeekCommandEvent else { return .noSuchContent }
            let delta = seekEvent.type == .beginSeeking ? 5.0 : 0.0
            self?.onSeek?(delta)
            return .success
        }
        
        commandCenter.seekBackwardCommand.addTarget { [weak self] event in
            guard let seekEvent = event as? MPSeekCommandEvent else { return .noSuchContent }
            let delta = seekEvent.type == .beginSeeking ? -5.0 : 0.0
            self?.onSeek?(delta)
            return .success
        }
        
        // Change Playback Position (scrub)
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .noSuchContent
            }
            self?.onChangePlaybackPosition?(positionEvent.positionTime)
            return .success
        }
        
        // Like/Dislike
        commandCenter.likeCommand.addTarget { [weak self] _ in
            self?.onLike?()
            return .success
        }
        commandCenter.likeCommand.isActive = true
        
        commandCenter.dislikeCommand.addTarget { [weak self] _ in
            self?.onDislike?()
            return .success
        }
        commandCenter.dislikeCommand.isActive = true
        
        // Enable
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    func updateNowPlaying(
        title: String,
        artist: String,
        album: String = "",
        duration: TimeInterval,
        currentTime: TimeInterval,
        rate: Float = 1.0,
        artwork: UIImage? = nil
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: rate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: artwork.size
            ) { _ in artwork }
        }
        
        nowPlayingInfo.nowPlayingInfo = info
    }
    
    func updatePlaybackState(playing: Bool) {
        nowPlayingInfo.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        nowPlayingInfo.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 
            nowPlayingInfo.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] ?? 0
    }
    
    func clearNowPlaying() {
        nowPlayingInfo.nowPlayingInfo = nil
    }
}
