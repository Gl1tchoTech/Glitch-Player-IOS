import SwiftUI
import WidgetKit

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }
    
    // MARK: - Small Widget
    
    var smallWidget: some View {
        VStack(spacing: 8) {
            // Artwork
            Group {
                if let imageData = entry.albumImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 48, height: 48)
            
            // Info
            Text(entry.trackName)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            
            Text(entry.artistName)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            // Play/Pause indicator
            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14))
                .foregroundColor(.pink)
        }
        .padding(12)
    }
    
    // MARK: - Medium Widget
    
    var mediumWidget: some View {
        HStack(spacing: 16) {
            // Artwork
            Group {
                if let imageData = entry.albumImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 64, height: 64)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Now Playing")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                Text(entry.trackName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                Text(entry.artistName)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 20) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18))
                
                Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pink)
                
                Image(systemName: "forward.fill")
                    .font(.system(size: 18))
            }
        }
        .padding(16)
    }
}
