import SwiftUI

struct AudiusSearchView: View {
    @Environment(BrowseViewModel.self) private var viewModel
    @Environment(PlayerViewModel.self) private var player
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search tracks, artists, albums...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
            }
            
            // Results
            if viewModel.isSearching {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if let results = viewModel.searchResults {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Tracks
                        if !results.tracks.isEmpty {
                            SearchResultSection(title: "Tracks", count: results.tracks.count) {
                                ForEach(results.tracks) { apiTrack in
                                    TrackRowView(track: apiTrack.toTrack(), onTap: {
                                        let tracks = results.tracks.map { $0.toTrack() }
                                        player.play(track: apiTrack.toTrack(), queue: tracks,
                                                    startIndex: results.tracks.firstIndex(where: { $0.id == apiTrack.id }) ?? 0)
                                    })
                                }
                            }
                        }
                        
                        // Albums
                        if !results.albums.isEmpty {
                            SearchResultSection(title: "Albums", count: results.albums.count) {
                                ForEach(results.albums) { album in
                                    SearchAlbumRow(album: album)
                                }
                            }
                        }
                        
                        // Artists
                        if !results.artists.isEmpty {
                            SearchResultSection(title: "Artists", count: results.artists.count) {
                                ForEach(results.artists) { artist in
                                    SearchArtistRow(artist: artist)
                                }
                            }
                        }
                        
                        // Playlists
                        if !results.playlists.isEmpty {
                            SearchResultSection(title: "Playlists", count: results.playlists.count) {
                                ForEach(results.playlists) { playlist in
                                    SearchPlaylistRow(playlist: playlist)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else if !searchText.isEmpty {
                Spacer()
                Text("No results found")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Search for music")
                        .font(.system(size: 16, weight: .medium))
                    Text("Find tracks, artists, and albums")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
}

struct SearchResultSection<Content: View>: View {
    let title: String
    let count: Int
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Section {
            content()
        } header: {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                    .textCase(nil)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .background(.background)
        }
    }
}

struct SearchAlbumRow: View {
    let album: APIAlbum
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: album.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "square.stack").foregroundColor(.gray))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name).font(.system(size: 15, weight: .medium)).lineLimit(1)
                Text(album.artists).font(.system(size: 13)).foregroundColor(.gray).lineLimit(1)
            }
            
            Spacer()
            
            Text("\(album.totalTracks) tracks").font(.system(size: 12)).foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}

struct SearchArtistRow: View {
    let artist: APIArtist
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: artist.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                default:
                    Circle().fill(.gray.opacity(0.2)).frame(width: 48, height: 48)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name).font(.system(size: 15, weight: .medium))
                if !artist.genres.isEmpty {
                    Text(artist.genres).font(.system(size: 13)).foregroundColor(.gray).lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}

struct SearchPlaylistRow: View {
    let playlist: APIPlaylist
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: playlist.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.2)).frame(width: 48, height: 48)
                        .overlay(Image(systemName: "music.note.list").foregroundColor(.gray))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name).font(.system(size: 15, weight: .medium)).lineLimit(1)
                Text("\(playlist.tracksCount) tracks • \(playlist.owner)")
                    .font(.system(size: 13)).foregroundColor(.gray).lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}
