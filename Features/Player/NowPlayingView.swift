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
                    player.currentArtworkColor.opacity(0.5),
                    Color.black.opacity(0.8),
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
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // Artwork
                artworkView
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                
                // Track Info
                VStack(spacing: 6) {
                    Text(player.currentTrack?.name ?? "Not Playing")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    
                    Text(player.currentTrack?.artists ?? "Unknown Artist")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                
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
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Text("-" + formatTime(max(0, player.duration - player.currentTime)))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
                }
                .padding(.top, 24)
                
                // Transport Controls
                HStack(spacing: 40) {
                    // Shuffle
                    Button(action: { player.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 18))
                            .foregroundColor(player.isShuffled ? .pink : .white.opacity(0.6))
                    }
                    
                    // Previous
                    Button(action: { player.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause
                    Button(action: { player.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black)
                                .offset(x: player.isPlaying ? 0 : 2)
                        }
                    }
                    
                    // Next
                    Button(action: { player.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    // Repeat
                    Button(action: { player.toggleRepeat() }) {
                        Image(systemName: player.repeatMode.systemImage)
                            .font(.system(size: 18))
                            .foregroundColor(player.repeatMode != .off ? .pink : .white.opacity(0.6))
                    }
                }
                .padding(.top, 28)
                
                // Bottom row: EQ, Sleep Timer
                HStack(spacing: 48) {
                    Button(action: { player.showingEqualizerSheet = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 22))
                            Text("EQ")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Button(action: { player.showingSleepTimerSheet = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "moon.zzz")
                                .font(.system(size: 22))
                            Text("Sleep")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.top, 24)
                
                Spacer(minLength: 20)
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
                .presentationDetents([.height(280)])
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
            } else if let url = URL(string: player.currentTrack?.albumImageURL ?? "") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        artworkPlaceholder
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.05))
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
        .scaleEffect(artworkScale)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: player.currentTrack?.id)
    }
    
    var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.15))
        }
    }
}
