import Foundation

// MARK: - API Client

final class GlitchiAPIClient {
    static let shared = GlitchiAPIClient()
    private let baseURL = "https://glitchi-stream.onrender.com"
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Health
    
    func healthCheck() async throws -> Bool {
        let data = try await get("/health")
        return !data.isEmpty
    }
    
    // MARK: - Files
    
    func listFiles() async throws -> FileListResponse {
        return try await get("/files/")
    }
    
    func streamURL(for filename: String) -> URL? {
        guard let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "\(baseURL)/files/stream?filename=\(encoded)")
    }
    
    func downloadURL(for filename: String) -> URL? {
        guard let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "\(baseURL)/files/download/\(encoded)")
    }
    
    func previewStreamURL(for trackID: String) -> URL {
        return URL(string: "\(baseURL)/files/stream/preview/\(trackID)")!
    }
    
    // MARK: - Search
    
    func search(query: String, type: String = "track,album,artist,playlist", limit: Int = 20) async throws -> SearchResults {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get("/search/?q=\(encodedQuery)&type=\(type)&limit=\(limit)")
    }
    
    // MARK: - Browse
    
    func browseAll() async throws -> BrowseAllResponse {
        return try await get("/browse/all")
    }
    
    func categories() async throws -> CategoryListResponse {
        return try await get("/browse/categories")
    }
    
    func categoryDetail(categoryID: String, limit: Int = 20) async throws -> SearchResults {
        return try await get("/browse/category/\(categoryID)?limit=\(limit)")
    }
    
    func newReleases(limit: Int = 20) async throws -> SearchResults {
        return try await get("/browse/new-releases?limit=\(limit)")
    }
    
    func featured(limit: Int = 20) async throws -> SearchResults {
        return try await get("/browse/featured?limit=\(limit)")
    }
    
    func trending(limit: Int = 20) async throws -> SearchResults {
        return try await get("/browse/trending?limit=\(limit)")
    }
    
    func personalized(categories: [String] = [], limit: Int = 12) async throws -> SearchResults {
        let cats = categories.map { $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0 }
        let catParams = cats.map { "cats=\($0)" }.joined(separator: "&")
        return try await get("/browse/personalized?\(catParams)&limit=\(limit)")
    }
    
    // MARK: - Album Tracks
    
    func albumTracks(albumID: String) async throws -> SearchResults {
        return try await get("/playlists/album-tracks/\(albumID)")
    }
    
    // MARK: - Download Tasks
    
    func startDownload(url: String, services: [String] = ["qobuz", "tidal"], quality: String = "LOSSLESS") async throws -> DownloadTaskResponse {
        let body = DownloadRequest(url: url, services: services, quality: quality)
        return try await post("/download/task", body: body)
    }
    
    func downloadProgress(taskID: String) async throws -> DownloadProgressResponse {
        return try await get("/download/progress/\(taskID)")
    }
    
    func downloadResult(taskID: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/download/result/\(taskID)")!
        let (data, _) = try await session.data(from: url)
        return data
    }
    
    func availableDownloaders() async throws -> AvailableDownloadersResponse {
        return try await get("/download/available")
    }
    
    func previewPlaylist(url: String) async throws -> SearchResults {
        let body = DownloadRequest(url: url)
        return try await post("/download/playlist-preview", body: body)
    }
    
    func downloadPlaylistBatch(url: String) async throws -> DownloadTaskResponse {
        let body = DownloadRequest(url: url)
        return try await post("/download/playlist-batch", body: body)
    }
    
    // MARK: - Private Helpers
    
    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Response Types

struct FileListResponse: Codable {
    let files: [FileItem]
}

struct FileItem: Codable, Identifiable {
    let filename: String
    let sizeMB: Double
    let `extension`: String
    
    enum CodingKeys: String, CodingKey {
        case filename
        case sizeMB = "size_mb"
        case `extension`
    }
    
    var id: String { filename }
}

struct SearchResults: Codable {
    let tracks: [APITrack]
    let albums: [APIAlbum]
    let artists: [APIArtist]
    let playlists: [APIPlaylist]
    let query: String
    
    init() {
        self.tracks = []
        self.albums = []
        self.artists = []
        self.playlists = []
        self.query = ""
    }
}

struct APITrack: Codable, Identifiable {
    let name: String
    let id: String
    let artists: String
    let album: String
    let albumImageURL: String
    let durationMs: Int
    let previewURL: String?
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name, id, artists, album
        case albumImageURL = "album_image_url"
        case durationMs = "duration_ms"
        case previewURL = "preview_url"
        case url
    }
    
    func toTrack() -> Track {
        Track(
            id: id,
            name: name,
            artists: artists,
            album: album,
            albumImageURL: albumImageURL,
            durationMs: durationMs,
            previewURL: previewURL,
            spotifyURL: url,
            source: "stream"
        )
    }
}

struct APIAlbum: Codable, Identifiable {
    let name: String
    let id: String
    let artists: String
    let releaseDate: String
    let totalTracks: Int
    let imageURL: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name, id, artists
        case releaseDate = "release_date"
        case totalTracks = "total_tracks"
        case imageURL = "image_url"
        case url
    }
}

struct APIArtist: Codable, Identifiable {
    let name: String
    let id: String
    let genres: String
    let imageURL: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name, id, genres
        case imageURL = "image_url"
        case url
    }
}

struct APIPlaylist: Codable, Identifiable {
    let name: String
    let id: String
    let description: String
    let imageURL: String
    let url: String
    let tracksCount: Int
    let owner: String
    
    enum CodingKeys: String, CodingKey {
        case name, id, description
        case imageURL = "image_url"
        case url
        case tracksCount = "tracks_count"
        case owner
    }
    
    func toPlaylist() -> Playlist {
        Playlist(
            id: id,
            name: name,
            playlistDescription: description,
            imageURL: imageURL,
            spotifyURL: url,
            tracksCount: tracksCount,
            owner: owner
        )
    }
}

struct CategoryItem: Codable, Identifiable {
    let id: String
    let name: String
    let color: String
}

struct CategoryListResponse: Codable {
    let categories: [CategoryItem]
}

struct BrowseAllResponse: Codable {
    let categories: [CategoryItem]
    let featured: SearchResults?
    let newReleases: SearchResults?
    let trending: SearchResults?
    
    enum CodingKeys: String, CodingKey {
        case categories
        case featured
        case newReleases = "new_releases"
        case trending
    }
}

struct DownloadRequest: Codable {
    let url: String
    let services: [String]?
    let quality: String?
    let timeoutS: Int?
    let trackMaxRetries: Int?
    
    init(url: String, services: [String]? = nil, quality: String? = nil, timeoutS: Int? = nil, trackMaxRetries: Int? = nil) {
        self.url = url
        self.services = services
        self.quality = quality
        self.timeoutS = timeoutS
        self.trackMaxRetries = trackMaxRetries
    }
    
    enum CodingKeys: String, CodingKey {
        case url, services, quality
        case timeoutS = "timeout_s"
        case trackMaxRetries = "track_max_retries"
    }
}

struct DownloadTaskResponse: Codable {
    let taskID: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case message
    }
}

struct DownloadProgressResponse: Codable {
    let status: String?
    let progress: Double?
    let filename: String?
    let error: String?
}

struct AvailableDownloadersResponse: Codable {
    let downloaders: [String]?
    let current: String?
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
