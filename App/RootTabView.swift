import SwiftUI

struct RootTabView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(ThemeManager.self) private var theme
    
    @State private var selectedTab: Tab = .library
    
    enum Tab: String, CaseIterable {
        case library = "Library"
        case browse = "Browse"
        case search = "Search"
        case playlists = "Playlists"
        case files = "Files"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .library: return "square.stack"
            case .browse: return "globe"
            case .search: return "magnifyingglass"
            case .playlists: return "music.note.list"
            case .files: return "folder"
            case .settings: return "gearshape"
            }
        }
        
        var filledIcon: String {
            switch self {
            case .library: return "square.stack.fill"
            case .browse: return "globe"
            case .search: return "magnifyingglass"
            case .playlists: return "music.note.list"
            case .files: return "folder.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tabItem {
                        Label(Tab.library.rawValue, systemImage: selectedTab == .library ? Tab.library.filledIcon : Tab.library.icon)
                    }
                    .tag(Tab.library)
                
                BrowseView()
                    .tabItem {
                        Label(Tab.browse.rawValue, systemImage: Tab.browse.icon)
                    }
                    .tag(Tab.browse)
                
                AudiusSearchView()
                    .tabItem {
                        Label(Tab.search.rawValue, systemImage: Tab.search.icon)
                    }
                    .tag(Tab.search)
                
                PlaylistsTabView()
                    .tabItem {
                        Label(Tab.playlists.rawValue, systemImage: Tab.playlists.icon)
                    }
                    .tag(Tab.playlists)
                
                FolderBrowserView()
                    .tabItem {
                        Label(Tab.files.rawValue, systemImage: selectedTab == .files ? Tab.files.filledIcon : Tab.files.icon)
                    }
                    .tag(Tab.files)
                
                SettingsView()
                    .tabItem {
                        Label(Tab.settings.rawValue, systemImage: selectedTab == .settings ? Tab.settings.filledIcon : Tab.settings.icon)
                    }
                    .tag(Tab.settings)
            }
            .tint(theme.accentColor.color)
            
            // Mini Player overlay — positioned above tab bar
            VStack(spacing: 0) {
                if player.currentTrack != nil {
                    MiniPlayerView()
                        .environment(player)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer().frame(height: 49)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: player.currentTrack != nil)
    }
}

// MARK: - Playlists Tab

struct PlaylistsTabView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerViewModel.self) private var player
    
    @State private var playlists: [Playlist] = []
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newDesc = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Playlists")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Create playlists from your library")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Button(action: { showCreateSheet = true }) {
                            Label("Create Playlist", systemImage: "plus")
                                .font(.system(size: 15, weight: .medium))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(.pink)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 80)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                            spacing: 20
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
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    Form {
                        Section("Playlist Details") {
                            TextField("Name", text: $newName)
                            TextField("Description (optional)", text: $newDesc)
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
                                guard !newName.isEmpty else { return }
                                _ = library.createPlaylist(name: newName, description: newDesc)
                                refreshPlaylists()
                                newName = ""
                                newDesc = ""
                                showCreateSheet = false
                            }
                            .disabled(newName.isEmpty)
                        }
                    }
                }
            }
        }
        .onAppear(perform: refreshPlaylists)
    }
    
    private func refreshPlaylists() {
        playlists = (try? library.allPlaylists()) ?? []
    }
}

// Note: PlaylistCard and PlaylistDetailView are defined in PlaylistsView.swift
