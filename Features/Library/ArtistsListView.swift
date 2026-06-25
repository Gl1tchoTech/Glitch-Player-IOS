import SwiftUI

struct ArtistsListView: View {
    @Environment(LibraryStore.self) private var library
    @State private var artists: [String] = []
    @State private var artistTracksMap: [String: [Track]] = [:]
    
    var body: some View {
        ScrollView {
            if artists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No Artists")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import music to see artists here")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(artists, id: \.self) { artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist, tracks: artistTracksMap[artist] ?? [])) {
                            ArtistRow(artist: artist, trackCount: artistTracksMap[artist]?.count ?? 0)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.leading, 68)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear(perform: loadArtists)
    }
    
    private func loadArtists() {
        artists = (try? library.allArtists()) ?? []
        for artist in artists {
            artistTracksMap[artist] = (try? library.tracks(forArtist: artist)) ?? []
        }
    }
}

struct ArtistRow: View {
    let artist: String
    let trackCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.gray.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artist)
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(trackCount) tracks")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.vertical, 12)
    }
}

struct ArtistDetailView: View {
    let artist: String
    let tracks: [Track]
    @Environment(PlayerViewModel.self) private var player
    
    var body: some View {
        List {
            if tracks.isEmpty {
                HStack {
                    Spacer()
                    Text("No tracks by this artist")
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
        .navigationTitle(artist)
    }
}
