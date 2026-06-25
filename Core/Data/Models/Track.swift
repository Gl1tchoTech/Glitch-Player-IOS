import Foundation
import SwiftData

@Model
final class Track: Identifiable, Codable {
    var id: String
    var name: String
    var artists: String
    var album: String
    var albumImageURL: String
    var durationMs: Int
    var previewURL: String?
    var spotifyURL: String
    
    // Local storage
    var fileURL: String?
    var isDownloaded: Bool
    var downloadDate: Date?
    
    // Metadata
    var source: String // "local", "stream", "downloaded"
    var isFavorite: Bool
    var dateAdded: Date
    
    // Playback state
    var lastPosition: Double
    var playCount: Int
    
    init(
        id: String = UUID().uuidString,
        name: String,
        artists: String = "",
        album: String = "",
        albumImageURL: String = "",
        durationMs: Int = 0,
        previewURL: String? = nil,
        spotifyURL: String = "",
        fileURL: String? = nil,
        isDownloaded: Bool = false,
        source: String = "stream",
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.artists = artists
        self.album = album
        self.albumImageURL = albumImageURL
        self.durationMs = durationMs
        self.previewURL = previewURL
        self.spotifyURL = spotifyURL
        self.fileURL = fileURL
        self.isDownloaded = isDownloaded
        self.downloadDate = nil
        self.source = source
        self.isFavorite = isFavorite
        self.dateAdded = Date()
        self.lastPosition = 0
        self.playCount = 0
    }
    
    // MARK: - Computed Properties
    
    var durationFormatted: String {
        let totalSeconds = durationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var artistList: [String] {
        artists.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var streamURL: URL? {
        if let previewURL = previewURL, let url = URL(string: previewURL) {
            return url
        }
        if !spotifyURL.isEmpty, let url = URL(string: "https://glitchi-stream.onrender.com/files/stream/preview/\(id)") {
            return url
        }
        if let fileURL = fileURL, let url = URL(string: fileURL) {
            return url
        }
        return nil
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, artists, album
        case albumImageURL = "album_image_url"
        case durationMs = "duration_ms"
        case previewURL = "preview_url"
        case spotifyURL = "url"
        case fileURL, isDownloaded, downloadDate, source, isFavorite
        case dateAdded, lastPosition, playCount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        artists = try container.decodeIfPresent(String.self, forKey: .artists) ?? ""
        album = try container.decodeIfPresent(String.self, forKey: .album) ?? ""
        albumImageURL = try container.decodeIfPresent(String.self, forKey: .albumImageURL) ?? ""
        durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs) ?? 0
        previewURL = try container.decodeIfPresent(String.self, forKey: .previewURL)
        spotifyURL = try container.decodeIfPresent(String.self, forKey: .spotifyURL) ?? ""
        fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)
        isDownloaded = try container.decodeIfPresent(Bool.self, forKey: .isDownloaded) ?? false
        downloadDate = try container.decodeIfPresent(Date.self, forKey: .downloadDate)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? "stream"
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        lastPosition = try container.decodeIfPresent(Double.self, forKey: .lastPosition) ?? 0
        playCount = try container.decodeIfPresent(Int.self, forKey: .playCount) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(artists, forKey: .artists)
        try container.encode(album, forKey: .album)
        try container.encode(albumImageURL, forKey: .albumImageURL)
        try container.encode(durationMs, forKey: .durationMs)
        try container.encodeIfPresent(previewURL, forKey: .previewURL)
        try container.encode(spotifyURL, forKey: .spotifyURL)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encode(isDownloaded, forKey: .isDownloaded)
        try container.encodeIfPresent(downloadDate, forKey: .downloadDate)
        try container.encode(source, forKey: .source)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(lastPosition, forKey: .lastPosition)
        try container.encode(playCount, forKey: .playCount)
    }
}
