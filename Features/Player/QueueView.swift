import SwiftUI

struct QueueView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Now Playing
                Section("Now Playing") {
                    if let track = player.currentTrack {
                        QueueTrackRow(
                            track: track,
                            isNowPlaying: true,
                            isPlaying: player.isPlaying,
                            onPlay: { player.play(track: track) }
                        )
                    }
                }
                
                // Up Next
                let upcoming = Array(player.queue.enumerated().filter {
                    $0.offset > player.queueIndex
                })
                
                if !upcoming.isEmpty {
                    Section("Up Next (\(upcoming.count))") {
                        ForEach(upcoming, id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                isNowPlaying: false,
                                isPlaying: false,
                                onPlay: { player.play(track: track, queue: player.queue, startIndex: index) },
                                onRemove: { player.removeFromQueue(at: index) }
                            )
                        }
                        .onMove { source, destination in
                            let queueIdx = player.queueIndex + 1
                            let adjustedFrom = source.first!
                            var adjustedTo = destination
                            if adjustedTo > source.first! { adjustedTo -= 1 }
                            
                            if adjustedFrom >= queueIdx && adjustedTo >= queueIdx {
                                player.moveInQueue(from: queueIdx + adjustedFrom - queueIdx, to: queueIdx + adjustedTo - queueIdx)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Spacer()
                            Text("Queue is empty")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        let toRemove = max(0, player.queue.count - player.queueIndex - 1)
                        for _ in 0..<toRemove {
                            player.removeFromQueue(at: player.queueIndex + 1)
                        }
                    }
                    .disabled(player.queue.count <= player.queueIndex + 1)
                }
            }
        }
    }
}

struct QueueTrackRow: View {
    let track: Track
    let isNowPlaying: Bool
    let isPlaying: Bool
    var onPlay: (() -> Void)?
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: URL(string: track.albumImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.system(size: 15, weight: isNowPlaying ? .semibold : .regular))
                    .foregroundColor(isNowPlaying ? .pink : .primary)
                    .lineLimit(1)
                
                Text(track.artists)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isNowPlaying && isPlaying {
                // Animated equalizer indicator
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.pink)
                            .frame(width: 2, height: [6, 12, 4][i])
                    }
                }
            }
            
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay?()
        }
    }
}
