import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}
    
    func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
        } catch {
            print("[AudioSession] Failed to configure: \(error)")
        }
    }
    
    func enableBackgroundAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AudioSession] Background activation failed: \(error)")
        }
    }
    
    func deactivate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AudioSession] Deactivation failed: \(error)")
        }
    }
    
    var currentRoute: String {
        let session = AVAudioSession.sharedInstance()
        let output = session.currentRoute.outputs.first
        return output?.portName ?? "Unknown"
    }
    
    var isHeadphonesConnected: Bool {
        let session = AVAudioSession.sharedInstance()
        return session.currentRoute.outputs.contains { output in
            output.portType == .headphones ||
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP
        }
    }
}
