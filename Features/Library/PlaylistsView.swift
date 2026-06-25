import SwiftUI

struct PlaylistsView: View {
    @Environment(LibraryStore.self) private var library
    @State private var playlists: [Playlist] = []
    @State private var showCreateSheet: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistDesc: String = ""
    
    var body: some View {
        ScrollView {
            if playlists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Playlists Yet")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Create your first playlist")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: { showCreateSheet = true }) {
                        Label("New Playlist", systemImage: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.pink)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 80)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createPlaylistSheet
        }
        .onAppear {
            playlists = (try? library.allPlaylists()) ?? []
        }
    }
    
    var createPlaylistSheet: some View {
        NavigationStack {
            Form {
                Section("Playlist Details") {
                    TextField("Name", text: $newPlaylistName)
                    TextField("Description (optional)", text: $newPlaylistDesc)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCreateSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        guard !newPlaylistName.isEmpty else { return }
                        _ = library.createPlaylist(name: newPlaylistName, description: newPlaylistDesc)
                        playlists = (try? library.allPlaylists()) ?? []
                        newPlaylistName = ""
                        newPlaylistDesc = ""
                        showCreateSheet = false
                    }
                    .disabled(newPlaylistName.isEmpty)
                }
            }
        }
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink.opacity(0.6), .purple.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fill)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(playlist.tracksCount) tracks")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    
    var body: some View {
        List {
            ForEach(playlist.tracks) { track in
                TrackRowView(track: track) {
                    player.play(track: track, queue: playlist.tracks, startIndex: playlist.tracks.firstIndex(of: track) ?? 0)
                }
            }
            .onDelete(perform: removeTracks)
        }
        .navigationTitle(playlist.name)
        .toolbar {
            EditButton()
        }
    }
    
    private func removeTracks(at offsets: IndexSet) {
        for index in offsets {
            library.removeTrack(playlist.tracks[index], from: playlist)
        }
    }
}
