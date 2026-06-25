import SwiftUI

@Observable
final class BrowseViewModel {
    
    let apiClient = GlitchiAPIClient.shared
    var downloadManager = DownloadManager.shared
    
    // State
    var categories: [CategoryItem] = []
    var trendingTracks: [APITrack] = []
    var featuredPlaylists: [APIPlaylist] = []
    var newReleaseAlbums: [APIAlbum] = []
    var searchResults: SearchResults?
    var categoryResults: [String: SearchResults] = [:]
    
    var isLoading: Bool = false
    var isSearching: Bool = false
    var errorMessage: String?
    
    // Search
    var searchQuery: String = ""
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Browse
    
    func loadBrowseAll() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let browse = try await apiClient.browseAll()
            categories = browse.categories
            
            if let trending = browse.trending {
                trendingTracks = trending.tracks
            }
            if let featured = browse.featured {
                featuredPlaylists = featured.playlists
            }
            if let newReleases = browse.newReleases {
                newReleaseAlbums = newReleases.albums
            }
        } catch {
            // Fallback: load individually
            await loadCategories()
            await loadTrending()
        }
    }
    
    func loadCategories() async {
        do {
            let response = try await apiClient.categories()
            categories = response.categories
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadTrending() async {
        do {
            let response = try await apiClient.trending()
            trendingTracks = response.tracks
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadFeatured() async {
        do {
            let response = try await apiClient.featured()
            featuredPlaylists = response.playlists
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadNewReleases() async {
        do {
            let response = try await apiClient.newReleases()
            newReleaseAlbums = response.albums
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadCategory(_ categoryID: String) async {
        guard categoryResults[categoryID] == nil else { return }
        
        do {
            let results = try await apiClient.categoryDetail(categoryID: categoryID)
            categoryResults[categoryID] = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Search
    
    func search(query: String) {
        searchQuery = query
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = nil
            return
        }
        
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            defer { isSearching = false }
            
            do {
                let results = try await apiClient.search(query: query)
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.searchResults = results
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = nil
        isSearching = false
    }
    
    // MARK: - Downloads
    
    func downloadTrack(_ track: APITrack) {
        Task {
            do {
                let downloader = DownloadManager.shared
                let downloadURL = track.url.isEmpty
                    ? "https://open.spotify.com/track/\(track.id)"
                    : track.url
                try await downloader.downloadTrack(
                    spotifyURL: downloadURL,
                    trackID: track.id
                )
            } catch {
                await MainActor.run {
                    errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        await loadBrowseAll()
        searchResults = nil
        categoryResults = [:]
    }
}
