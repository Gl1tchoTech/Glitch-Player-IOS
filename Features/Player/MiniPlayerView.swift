import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlayerViewModel.self) private var player
    @State private var dragOffset: CGFloat = 0
    @State private var showingNowPlaying: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Slim progress bar
            if player.currentTrack != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(height: 2)
                        Capsule()
                            .fill(.pink)
                            .frame(width: progressWidth(in: geo.size.width), height: 2)
                    }
                }
                .frame(height: 2)
            }
            
            // Mini player content
            HStack(spacing: 12) {
                // Artwork with corner radius
                Group {
                    if let artwork = player.currentArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        AsyncImage(url: URL(string: player.currentTrack?.albumImageURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                
                // Track info
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.currentTrack?.name ?? "Not Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(player.currentTrack?.artists ?? "Select a track")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause
                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                .frame(width: 40, height: 40)
                
                // Next
                Button(action: { player.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .frame(width: 36, height: 36)
                .opacity(player.queue.count > 1 ? 1 : 0.3)
                .disabled(player.queue.count <= 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .onTapGesture {
            showingNowPlaying = true
        }
        .fullScreenCover(isPresented: $showingNowPlaying) {
            NowPlayingView()
                .environment(player)
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0, totalWidth.isFinite, totalWidth > 0 else { return 0 }
        let ratio = player.currentTime / player.duration
        guard ratio.isFinite else { return 0 }
        return totalWidth * CGFloat(max(0, min(1, ratio)))
    }
}
