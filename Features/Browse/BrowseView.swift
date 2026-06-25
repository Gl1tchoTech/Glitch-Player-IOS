import SwiftUI

struct BrowseView: View {
    @Environment(BrowseViewModel.self) private var viewModel
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
                // Tab picker
                Picker("Browse", selection: $selectedTab) {
                    ForEach(BrowseTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
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
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.trendingTracks) { apiTrack in
                        let track = apiTrack.toTrack()
                        BrowseTrackRow(apiTrack: apiTrack, track: track)
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
                    spacing: 16
                ) {
                    ForEach(viewModel.newReleaseAlbums) { album in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: album.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                default:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.gray.opacity(0.2))
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay(Image(systemName: "square.stack").foregroundColor(.gray))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text(album.artists)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
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
                    spacing: 16
                ) {
                    ForEach(viewModel.featuredPlaylists) { playlist in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: playlist.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                default:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.gray.opacity(0.2))
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay(Image(systemName: "music.note.list").foregroundColor(.gray))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text("\(playlist.tracksCount) tracks")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
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
                .foregroundColor(.gray)
        }
        .padding(.top, 80)
    }
}

struct BrowseTrackRow: View {
    let apiTrack: APITrack
    let track: Track
    @Environment(PlayerViewModel.self) private var player
    @Environment(BrowseViewModel.self) private var viewModel
    
    var body: some View {
        TrackRowView(track: track, onTap: {
            player.play(track: track, queue: viewModel.trendingTracks.map { $0.toTrack() },
                        startIndex: viewModel.trendingTracks.firstIndex(where: { $0.id == track.id }) ?? 0)
        }, onDownload: {
            viewModel.downloadTrack(apiTrack)
        })
    }
}
