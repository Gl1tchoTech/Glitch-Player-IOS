import Foundation
import AppIntents

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Play/Pause"
    static var description = IntentDescription("Play or pause the current track")
    
    func perform() async throws -> some IntentResult {
        // Post notification to main app to toggle play/pause
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("com.errorstream.widget.playpause" as CFString),
            nil, nil, true
        )
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description = IntentDescription("Skip to the next track")
    
    func perform() async throws -> some IntentResult {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("com.errorstream.widget.next" as CFString),
            nil, nil, true
        )
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Go back to the previous track")
    
    func perform() async throws -> some IntentResult {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("com.errorstream.widget.previous" as CFString),
            nil, nil, true
        )
        return .result()
    }
}
