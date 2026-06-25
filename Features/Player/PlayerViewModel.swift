import SwiftUI
import AVFoundation

@Observable
final class PlayerViewModel {
    
    // MARK: - Dependencies
    
    var audioEngine: AudioEngineCoordinator?
    var equalizerManager: EqualizerManager?
    var remoteCommandManager: RemoteCommandManager?
    var libraryStore: LibraryStore?
    
    // MARK: - State
    
    var currentTrack: Track?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isBuffering: Bool = false
    var currentArtwork: UIImage?
    var currentArtworkColor: Color = .gray
    
    // Queue
    var queue: [Track] = []
    var queueIndex: Int = 0
    
    // Modes
    var isShuffled: Bool = false
    var repeatMode: RepeatMode = .off
    var isMuted: Bool = false
    var volume: Float = 0.75
    
    // Sleep Timer
    var sleepTimerMinutes: Int = 0
    var sleepTimerEndDate: Date?
    
    // Sheet presentation
    var showingQueueSheet: Bool = false
    var showingEqualizerSheet: Bool = false
    var showingSleepTimerSheet: Bool = false
    
    // Error
    var errorMessage: String?
    var showError: Bool = false
    
    private var sleepTimerTask: Task<Void, Never>?
    
    // MARK: - Init
    
    init() {
        // No-op: call configure(...) to wire dependencies
    }
    
    func configure(
        audioEngine: AudioEngineCoordinator,
        equalizerManager: EqualizerManager,
        remoteCommandManager: RemoteCommandManager
    ) {
        self.audioEngine = audioEngine
        self.equalizerManager = equalizerManager
        self.remoteCommandManager = remoteCommandManager
        
        setupEngineCallbacks()
        setupRemoteCommands()
    }
    
    private func setupEngineCallbacks() {
        audioEngine?.onPlaybackStateChanged = { [weak self] playing in
            self?.isPlaying = playing
        }
        
        audioEngine?.onTimeUpdated = { [weak self] time in
            self?.currentTime = time
        }
        
        audioEngine?.onTrackFinished = { [weak self] in
            self?.handleTrackFinished()
        }
        
        audioEngine?.onError = { [weak self] error in
            self?.errorMessage = error.localizedDescription
            self?.showError = true
        }
    }
    
    private func setupRemoteCommands() {
        remoteCommandManager?.onTogglePlayPause = { [weak self] in self?.togglePlayPause() }
        remoteCommandManager?.onNextTrack = { [weak self] in self?.nextTrack() }
        remoteCommandManager?.onPreviousTrack = { [weak self] in self?.previousTrack() }
        remoteCommandManager?.onChangePlaybackPosition = { [weak self] position in self?.seek(to: position) }
    }
    
    // MARK: - Playback Actions
    
    var gaplessEnabled: Bool {
        get { audioEngine?.gaplessEnabled ?? true }
        set { audioEngine?.gaplessEnabled = newValue }
    }
    
    func play(track: Track, queue: [Track] = [], startIndex: Int = 0) {
        guard let audioEngine else { return }
        self.currentTrack = track
        if !queue.isEmpty {
            self.queue = queue
            self.queueIndex = startIndex
        } else {
            self.queue = [track]
            self.queueIndex = 0
        }
        
        Task {
            do {
                let source: AudioSource
                if track.isDownloaded, let fileURL = track.fileURL {
                    // Try as absolute path first, then relative to downloads directory
                    let localURL: URL
                    if fileURL.hasPrefix("/") || fileURL.hasPrefix("file://") {
                        localURL = URL(fileURLWithPath: fileURL.replacingOccurrences(of: "file://", with: ""))
                    } else {
                        localURL = DownloadManager.shared.localFileURL(for: fileURL)
                    }
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        source = .localFile(url: localURL)
                    } else if let previewURL = track.previewURL, let previewUrl = URL(string: previewURL) {
                        source = .remoteStream(url: previewUrl)
                    } else {
                        source = .apiPreview(trackID: track.id)
                    }
                } else if let previewURL = track.previewURL, let url = URL(string: previewURL) {
                    source = .remoteStream(url: url)
                } else {
                    source = .apiPreview(trackID: track.id)
                }
                
                // Pre-load next track for gapless
                if gaplessEnabled, queueIndex + 1 < queue.count {
                    let nextIdx = queueIndex + 1
                    let nextTrack = queue[nextIdx]
                    if nextTrack.isDownloaded, let nextFile = nextTrack.fileURL {
                        let nextURL = DownloadManager.shared.localFileURL(for: nextFile)
                        if FileManager.default.fileExists(atPath: nextURL.path) {
                            await audioEngine.scheduleNext(.localFile(url: nextURL))
                        }
                    }
                }
                
                try await audioEngine.load(source: source)
                audioEngine.play()
                isPlaying = true
                duration = audioEngine.duration
                
                updateNowPlaying()
                libraryStore?.updatePlayCount(track)
                loadArtwork(for: track)
            } catch {
                self.errorMessage = "Failed to play: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    func togglePlayPause() {
        guard let audioEngine else { return }
        if isPlaying {
            audioEngine.pause()
        } else {
            audioEngine.play()
        }
        isPlaying.toggle()
        updateNowPlaying()
    }
    
    func nextTrack() {
        guard queueIndex < queue.count - 1 else {
            if repeatMode == .all {
                queueIndex = 0
                reshuffleIfNeeded()
                if let track = queue.first {
                    play(track: track, queue: queue)
                }
            }
            return
        }
        
        queueIndex += 1
        let idx = isShuffled && !shuffledIndices.isEmpty
            ? min(queueIndex, shuffledIndices.count - 1)
            : queueIndex
        let actual = isShuffled ? shuffledIndices[idx] : idx
        
        guard actual < queue.count else { return }
        play(track: queue[actual], queue: queue, startIndex: queueIndex)
    }
    
    func previousTrack() {
        guard queueIndex > 0 else { return }
        queueIndex -= 1
        let idx = isShuffled && !shuffledIndices.isEmpty
            ? min(queueIndex, shuffledIndices.count - 1)
            : queueIndex
        let actual = isShuffled ? shuffledIndices[idx] : idx
        
        guard actual < queue.count else { return }
        play(track: queue[actual], queue: queue, startIndex: queueIndex)
    }
    
    func seek(to time: TimeInterval) {
        guard let audioEngine else { return }
        audioEngine.seek(to: time)
        currentTime = time
        updateNowPlaying()
    }
    
    func setVolume(_ vol: Float) {
        guard let audioEngine else { return }
        volume = vol
        audioEngine.volume = vol
    }
    
    func toggleMute() {
        guard let audioEngine else { return }
        isMuted.toggle()
        audioEngine.isMuted = isMuted
    }
    
    // MARK: - Shuffle / Repeat
    
    private var shuffledIndices: [Int] = []
    
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            reshuffleIfNeeded()
        }
    }
    
    func toggleRepeat() {
        repeatMode = repeatMode.next
    }
    
    private func reshuffleIfNeeded() {
        guard !queue.isEmpty, isShuffled else { return }
        var indices = Array(0..<queue.count)
        if let currentIdx = indices.firstIndex(of: queueIndex) {
            indices.remove(at: currentIdx)
        }
        indices.shuffle()
        shuffledIndices = [queueIndex] + indices
    }
    
    // MARK: - Queue Management
    
    func addToQueue(_ track: Track) {
        queue.append(track)
        if isShuffled { reshuffleIfNeeded() }
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count, index != queueIndex else { return }
        queue.remove(at: index)
        if index < queueIndex { queueIndex -= 1 }
        if isShuffled { reshuffleIfNeeded() }
    }
    
    func moveInQueue(from: Int, to: Int) {
        guard from < queue.count, to < queue.count else { return }
        let track = queue.remove(at: from)
        queue.insert(track, at: to)
        
        // Adjust current index
        if from == queueIndex {
            queueIndex = to
        } else {
            if from < queueIndex && to >= queueIndex { queueIndex -= 1 }
            else if from > queueIndex && to <= queueIndex { queueIndex += 1 }
        }
        
        if isShuffled { reshuffleIfNeeded() }
    }
    
    // MARK: - Sleep Timer
    
    func setSleepTimer(minutes: Int) {
        sleepTimerTask?.cancel()
        sleepTimerMinutes = minutes
        sleepTimerEndDate = Date().addingTimeInterval(Double(minutes) * 60)
        
        guard minutes > 0 else { return }
        
        sleepTimerTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.audioEngine?.pause()
                self.isPlaying = false
                self.sleepTimerMinutes = 0
                self.sleepTimerEndDate = nil
            }
        }
    }
    
    func cancelSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerMinutes = 0
        sleepTimerEndDate = nil
    }
    
    // MARK: - Now Playing Info
    
    func updateNowPlaying() {
        guard let track = currentTrack else { return }
        guard let remoteCommandManager else { return }
        remoteCommandManager.updateNowPlaying(
            title: track.name,
            artist: track.artists,
            album: track.album,
            duration: duration,
            currentTime: currentTime,
            rate: isPlaying ? 1.0 : 0.0,
            artwork: currentArtwork
        )
    }
    
    func loadArtwork(for track: Track) {
        guard let url = URL(string: track.albumImageURL) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.currentArtwork = image
                        self.currentArtworkColor = extractDominantColor(from: image)
                        self.updateNowPlaying()
                    }
                }
            } catch {
                // Silently fail for artwork
            }
        }
    }
    
    private func extractDominantColor(from image: UIImage) -> Color {
        // Simplified: use a vibrant default
        return .pink
    }
    
    // MARK: - Track Finished Handler
    
    private func handleTrackFinished() {
        guard let audioEngine else { return }
        if repeatMode == .one {
            seek(to: 0)
            audioEngine.play()
        } else if gaplessEnabled && audioEngine.switchToNextNode() {
            // Gapless transition succeeded — advance queue index
            if queueIndex < queue.count - 1 {
                queueIndex += 1
                currentTrack = queue[queueIndex]
            } else if repeatMode == .all {
                queueIndex = 0
                currentTrack = queue.first
            }
            duration = audioEngine.duration
            updateNowPlaying()
            if let track = currentTrack {
                libraryStore?.updatePlayCount(track)
                loadArtwork(for: track)
            }
        } else {
            nextTrack()
        }
    }
    
    // MARK: - Crossfade (placeholder)
    
    var crossfadeDuration: Double = 0
}
