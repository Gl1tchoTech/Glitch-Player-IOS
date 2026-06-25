import SwiftUI

struct AlbumsGridView: View {
    @Environment(LibraryStore.self) private var library
    @State private var albums: [String] = []
    @State private var albumTracksMap: [String: [Track]] = [:]
    
    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
    var body: some View {
        ScrollView {
            if albums.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No Albums")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import music to see albums here")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums, id: \.self) { album in
                        NavigationLink(destination: AlbumDetailView(album: album, tracks: albumTracksMap[album] ?? [])) {
                            AlbumCard(album: album, trackCount: albumTracksMap[album]?.count ?? 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .onAppear(perform: loadAlbums)
    }
    
    private func loadAlbums() {
        albums = (try? library.allAlbums()) ?? []
        for album in albums {
            albumTracksMap[album] = (try? library.tracks(forAlbum: album)) ?? []
        }
    }
}

struct AlbumCard: View {
    let album: String
    let trackCount: Int
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.gray.opacity(0.12))
                    .aspectRatio(1, contentMode: .fill)
                
                Image(systemName: "square.stack.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(trackCount) tracks")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }
}

struct AlbumDetailView: View {
    let album: String
    let tracks: [Track]
    @Environment(PlayerViewModel.self) private var player
    
    var body: some View {
        List {
            if tracks.isEmpty {
                HStack {
                    Spacer()
                    Text("No tracks in this album")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                ForEach(tracks) { track in
                    TrackRowView(track: track) {
                        player.play(track: track, queue: tracks, startIndex: tracks.firstIndex(of: track) ?? 0)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(album)
    }
}
