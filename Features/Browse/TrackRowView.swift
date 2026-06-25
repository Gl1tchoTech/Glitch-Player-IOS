import SwiftUI

struct TrackRowView: View {
    let track: Track
    var onTap: (() -> Void)?
    var onDownload: (() -> Void)?
    var showDownloadButton: Bool = true
    
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    @State private var isDownloading: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: URL(string: track.albumImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(isCurrentTrack ? .pink : .primary)
                
                HStack(spacing: 4) {
                    Text(track.artists)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if !track.album.isEmpty {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(track.album)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Duration
            Text(track.durationFormatted)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            // Actions
            HStack(spacing: 12) {
                // Favorite
                Button(action: { library.toggleFavorite(track) }) {
                    Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(track.isFavorite ? .pink : .gray)
                }
                
                // Download
                if showDownloadButton && !track.isDownloaded {
                    Button(action: {
                        isDownloading = true
                        onDownload?()
                    }) {
                        if isDownloading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                } else if track.isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
    
    private var isCurrentTrack: Bool {
        player.currentTrack?.id == track.id
    }
}
