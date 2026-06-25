import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlayerViewModel.self) private var player
    @State private var dragOffset: CGFloat = 0
    @State private var showingNowPlaying: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if player.currentTrack != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.ultraThinMaterial)
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
                // Artwork
                AsyncImage(url: URL(string: player.currentTrack?.albumImageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.name ?? "Not Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    
                    Text(player.currentTrack?.artists ?? "Select a track")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause
                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .frame(width: 40, height: 40)
                
                // Next
                Button(action: { player.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
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
        .onTapGesture {
            showingNowPlaying = true
        }
        .fullScreenCover(isPresented: $showingNowPlaying) {
            NowPlayingView()
                .environment(player)
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return totalWidth * CGFloat(player.currentTime / player.duration)
    }
}
