import SwiftUI

struct BrowseView: View {
    @Environment(BrowseViewModel.self) private var viewModel
    @Environment(PlayerViewModel.self) private var player
    @State private var selectedTab: BrowseTab = .trending
    
    enum BrowseTab: String, CaseIterable {
        case trending = "Trending"
        case genres = "Genres"
        case newReleases = "New"
        case featured = "Featured"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pill picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(BrowseTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTab == tab
                                            ? Color.pink
                                            : Color.gray.opacity(0.12)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                // Content
                Group {
                    switch selectedTab {
                    case .trending:
                        trendingView
                    case .genres:
                        GenreListView()
                    case .newReleases:
                        newReleasesView
                    case .featured:
                        featuredView
                    }
                }
            }
            .navigationTitle("Browse")
            .task {
                await viewModel.loadBrowseAll()
            }
        }
    }
    
    // MARK: - Trending
    
    var trendingView: some View {
        ScrollView {
            if viewModel.trendingTracks.isEmpty {
                loadingState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.trendingTracks) { apiTrack in
                        let track = apiTrack.toTrack()
                        let tracks = viewModel.trendingTracks.map { $0.toTrack() }
                        TrackRowView(track: track, onTap: {
                            player.play(track: track, queue: tracks,
                                        startIndex: viewModel.trendingTracks.firstIndex(where: { $0.id == track.id }) ?? 0)
                        }, onDownload: {
                            viewModel.downloadTrack(apiTrack)
                        })
                        Divider()
                            .padding(.leading, 72)
                            .opacity(0.4)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .refreshable {
            await viewModel.loadTrending()
        }
    }
    
    // MARK: - New Releases
    
    var newReleasesView: some View {
        ScrollView {
            if viewModel.newReleaseAlbums.isEmpty {
                loadingState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 20
                ) {
                    ForEach(viewModel.newReleaseAlbums) { album in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: album.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                                default:
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.gray.opacity(0.1))
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay(
                                            Image(systemName: "square.stack")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                Text(album.artists)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
            }
        }
        .refreshable {
            await viewModel.loadNewReleases()
        }
    }
    
    // MARK: - Featured
    
    var featuredView: some View {
        ScrollView {
            if viewModel.featuredPlaylists.isEmpty {
                loadingState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 20
                ) {
                    ForEach(viewModel.featuredPlaylists) { playlist in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: playlist.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                                default:
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.gray.opacity(0.1))
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay(
                                            Image(systemName: "music.note.list")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(playlist.tracksCount) tracks")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
            }
        }
        .refreshable {
            await viewModel.loadFeatured()
        }
    }
    
    // MARK: - Loading
    
    var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.top, 80)
    }
}

