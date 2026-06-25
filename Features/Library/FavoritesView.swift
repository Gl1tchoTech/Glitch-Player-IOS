import SwiftUI

struct FavoritesView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    @State private var favorites: [Track] = []
    
    var body: some View {
        Group {
            if favorites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Favorites")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Tap the heart icon on tracks to add them here")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)
            } else {
                List {
                    ForEach(favorites) { track in
                        TrackRowView(track: track) {
                            player.play(track: track, queue: favorites, startIndex: favorites.firstIndex(of: track) ?? 0)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            favorites = (try? library.favoriteTracks()) ?? []
        }
    }
}
