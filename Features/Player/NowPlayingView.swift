import SwiftUI

struct NowPlayingView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDraggingSlider: Bool = false
    @State private var dragTime: TimeInterval = 0
    @State private var artworkScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background gradient from artwork
            LinearGradient(
                gradient: Gradient(colors: [
                    player.currentArtworkColor.opacity(0.6),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(player.currentTrack?.album ?? "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { player.showingQueueSheet = true }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        AirPlayRouteButton()
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
                
                // Artwork
                artworkView
                    .padding(.horizontal, 40)
                
                // Track Info
                VStack(spacing: 4) {
                    Text(player.currentTrack?.name ?? "Not Playing")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(player.currentTrack?.artists ?? "Unknown Artist")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.top, 32)
                
                // Progress Slider
                VStack(spacing: 0) {
                    CustomSlider(
                        value: isDraggingSlider ? $dragTime : .init(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        range: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if editing {
                                dragTime = player.currentTime
                            } else {
                                player.seek(to: dragTime)
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    
                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(formatTime(player.duration - player.currentTime))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 2)
                }
                .padding(.top, 24)
                
                // Controls
                HStack(spacing: 32) {
                    // Shuffle
                    Button(action: { player.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundColor(player.isShuffled ? .pink : .white.opacity(0.7))
                    }
                    
                    // Previous
                    Button(action: { player.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause
                    Button(action: { player.togglePlayPause() }) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }
                    
                    // Next
                    Button(action: { player.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // Repeat
                    Button(action: { player.toggleRepeat() }) {
                        Image(systemName: player.repeatMode.systemImage)
                            .font(.system(size: 20))
                            .foregroundColor(player.repeatMode != .off ? .pink : .white.opacity(0.7))
                    }
                }
                .padding(.top, 24)
                
                // Bottom row: EQ, AirPlay, Sleep Timer
                HStack(spacing: 40) {
                    Button(action: { player.showingEqualizerSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: { player.showingSleepTimerSheet = true }) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .sheet(isPresented: Binding(
            get: { player.showingQueueSheet },
            set: { player.showingQueueSheet = $0 }
        )) {
            QueueView()
                .environment(player)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { player.showingEqualizerSheet },
            set: { player.showingEqualizerSheet = $0 }
        )) {
            EqualizerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { player.showingSleepTimerSheet },
            set: { player.showingSleepTimerSheet = $0 }
        )) {
            SleepTimerSheet()
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Artwork
    
    var artworkView: some View {
        Group {
            if let artwork = player.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                AsyncImage(url: URL(string: player.currentTrack?.albumImageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    default:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                            )
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .scaleEffect(artworkScale)
    }
}
