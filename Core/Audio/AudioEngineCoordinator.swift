import AVFoundation
import MediaPlayer

@Observable
final class AudioEngineCoordinator {
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var nextPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var nextAudioFile: AVAudioFile?
    
    // State
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    var volume: Float = 1.0 {
        didSet { playerNode.volume = volume }
    }
    var isMuted: Bool = false {
        didSet { playerNode.volume = isMuted ? 0 : volume }
    }
    
    // Gapless playback
    var gaplessEnabled: Bool = true
    private var isSchedulingNext: Bool = false
    
    // Callbacks
    var onPlaybackStateChanged: ((Bool) -> Void)?
    var onTimeUpdated: ((TimeInterval) -> Void)?
    var onTrackFinished: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    private var displayLink: CADisplayLink?
    
    // Equalizer
    let equalizer = AVAudioUnitEQ(numberOfBands: 10)
    
    // MARK: - Init
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.attach(equalizer)
        
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: equalizer, format: format)
        engine.connect(equalizer, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            onError?(error)
        }
    }
    
    // MARK: - Playback Control
    
    func load(source: AudioSource) async throws {
        stop()
        
        switch source {
        case .localFile(let url), .downloadedTrack(_, let url):
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            self.duration = Double(file.length) / file.fileFormat.sampleRate
            self.playerNode.scheduleFile(file, at: nil)
            
        case .remoteStream(let url):
            guard let streamURL = source.url else { throw AudioError.invalidSource }
            let (data, _) = try await URLSession.shared.data(from: streamURL)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tempURL)
            let file = try AVAudioFile(forReading: tempURL)
            self.audioFile = file
            self.duration = Double(file.length) / file.fileFormat.sampleRate
            self.playerNode.scheduleFile(file, at: nil)

        case .apiStream, .apiPreview:
            guard let streamURL = source.url else { throw AudioError.invalidSource }
            let (data, _) = try await URLSession.shared.data(from: streamURL)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tempURL)
            let file = try AVAudioFile(forReading: tempURL)
            self.audioFile = file
            self.duration = Double(file.length) / file.fileFormat.sampleRate
            self.playerNode.scheduleFile(file, at: nil)
        }
    }
    
    func play() {
        if !engine.isRunning {
            do { try engine.start() } catch { onError?(error); return }
        }
        playerNode.play()
        isPlaying = true
        startDisplayLink()
    }
    
    func pause() {
        playerNode.pause()
        isPlaying = false
        stopDisplayLink()
    }
    
    func stop() {
        playerNode.stop()
        playerNode.reset()
        isPlaying = false
        currentTime = 0
        stopDisplayLink()
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }
    
    func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }
        let sampleRate = audioFile.fileFormat.sampleRate
        let framePosition = AVAudioFramePosition(time * sampleRate)
        
        playerNode.stop()
        playerNode.scheduleSegment(
            audioFile,
            startingFrame: framePosition,
            frameCount: AVAudioFrameCount(audioFile.length - framePosition),
            at: nil
        )
        
        if isPlaying {
            playerNode.play()
        }
        currentTime = time
    }
    
    // MARK: - Display Link
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateTime() {
        guard let audioFile = audioFile, let nodeTime = playerNode.lastRenderTime else { return }
        guard let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else { return }
        
        let time = Double(playerTime.sampleTime) / audioFile.fileFormat.sampleRate
        currentTime = time
        onTimeUpdated?(time)
        
        // Check if playback finished
        if time >= duration - 0.1 {
            onTrackFinished?()
        }
    }
    
    // MARK: - Gapless Scheduling
    
    func scheduleNext(_ source: AudioSource) async {
        guard gaplessEnabled else { return }
        
        do {
            let nextNode = AVAudioPlayerNode()
            engine.attach(nextNode)
            engine.connect(nextNode, to: equalizer, format: nil)
            
            let file: AVAudioFile
            switch source {
            case .localFile(let url), .downloadedTrack(_, let url):
                file = try AVAudioFile(forReading: url)
            case .remoteStream, .apiStream, .apiPreview:
                guard let streamURL = source.url else { throw AudioError.invalidSource }
                let (data, _) = try await URLSession.shared.data(from: streamURL)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("next_" + UUID().uuidString + ".mp3")
                try data.write(to: tempURL)
                file = try AVAudioFile(forReading: tempURL)
            }
            
            // Schedule the file on the next node (ready to play when switched)
            nextNode.scheduleFile(file, at: nil)
            nextAudioFile = file
            nextPlayerNode = nextNode
            isSchedulingNext = true
        } catch {
            onError?(error)
        }
    }
    
    /// Switch to the gapless-scheduled next player node. Returns false if no next node available.
    @discardableResult
    func switchToNextNode() -> Bool {
        guard let nextNode = nextPlayerNode, let nextFile = nextAudioFile else { return false }
        
        // Stop and detach old node
        playerNode.stop()
        playerNode.reset()
        engine.detach(playerNode)
        
        // Swap in the next node as primary and start it
        self.playerNode = nextNode
        self.playerNode.play()
        
        self.audioFile = nextFile
        self.duration = Double(nextFile.length) / nextFile.fileFormat.sampleRate
        self.currentTime = 0
        
        // Reapply volume/mute state to new node
        self.playerNode.volume = isMuted ? 0 : volume
        
        // Clear next-scheduled references
        self.nextPlayerNode = nil
        self.nextAudioFile = nil
        self.isSchedulingNext = false
        
        // Restart display link tracking on the new node
        stopDisplayLink()
        startDisplayLink()
        
        return true
    }
}

enum AudioError: LocalizedError {
    case invalidSource
    case fileNotFound
    case playbackError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSource: return "Invalid audio source"
        case .fileNotFound: return "Audio file not found"
        case .playbackError(let msg): return "Playback error: \(msg)"
        }
    }
}
