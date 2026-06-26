import SwiftUI
import WidgetKit

struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(
            date: Date(),
            trackName: "Track Name",
            artistName: "Artist",
            isPlaying: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        let entry = NowPlayingEntry(
            date: Date(),
            trackName: "Bohemian Rhapsody",
            artistName: "Queen",
            isPlaying: true
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        // Read from UserDefaults shared with main app
        let defaults = UserDefaults(suiteName: "group.com.errorstream.app")
        let entry = NowPlayingEntry(
            date: Date(),
            trackName: defaults?.string(forKey: "nowPlayingTitle") ?? "Not Playing",
            artistName: defaults?.string(forKey: "nowPlayingArtist") ?? "Open ErrorStream",
            isPlaying: defaults?.bool(forKey: "nowPlayingIsPlaying") ?? false,
            albumImageData: defaults?.data(forKey: "nowPlayingArtwork")
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let trackName: String
    let artistName: String
    let isPlaying: Bool
    var albumImageData: Data? = nil
}

struct NowPlayingWidget: Widget {
    let kind: String = "NowPlayingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Now Playing")
        .description("Shows the currently playing track and quick controls.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
