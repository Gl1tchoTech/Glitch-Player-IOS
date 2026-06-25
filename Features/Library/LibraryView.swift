import SwiftUI

struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    @State private var selectedTab: LibraryTab = .playlists
    @State private var searchText: String = ""
    
    enum LibraryTab: String, CaseIterable {
        case playlists = "Playlists"
        case albums = "Albums"
        case artists = "Artists"
        case songs = "Songs"
        case favorites = "Favorites"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("View", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Content
                Group {
                    switch selectedTab {
                    case .playlists:
                        PlaylistsView()
                    case .albums:
                        AlbumsGridView()
                    case .artists:
                        ArtistsListView()
                    case .songs:
                        SongsListView()
                    case .favorites:
                        FavoritesView()
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search library")
        }
    }
}

// MARK: - Songs List View

struct SongsListView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    
    @State private var tracks: [Track] = []
    
    var body: some View {
        Group {
            if tracks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No Songs")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import music or add tracks from Browse")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
            } else {
                List {
                    ForEach(tracks) { track in
                        TrackRowView(track: track) {
                            player.play(track: track, queue: tracks, startIndex: tracks.firstIndex(of: track) ?? 0)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            tracks = (try? library.allTracks()) ?? []
        }
    }
}
