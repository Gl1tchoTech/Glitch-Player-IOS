import Foundation
import SwiftData

@Model
final class DownloadedTrack: Identifiable, Codable {
    var id: String
    var trackID: String        // Spotify/API track ID
    var filename: String       // On-disk filename
    var localPath: String      // Full path in Documents/MeloMusic/
    var fileSizeMB: Double
    var serverFilename: String // Original filename on server
    var downloadTaskID: String? // API download task ID
    var dateDownloaded: Date
    var sourceURL: String      // Original URL used to download
    
    init(
        id: String = UUID().uuidString,
        trackID: String,
        filename: String,
        localPath: String,
        fileSizeMB: Double = 0,
        serverFilename: String = "",
        downloadTaskID: String? = nil,
        sourceURL: String = ""
    ) {
        self.id = id
        self.trackID = trackID
        self.filename = filename
        self.localPath = localPath
        self.fileSizeMB = fileSizeMB
        self.serverFilename = serverFilename
        self.downloadTaskID = downloadTaskID
        self.dateDownloaded = Date()
        self.sourceURL = sourceURL
    }
    
    enum CodingKeys: String, CodingKey {
        case id, trackID, filename, localPath, fileSizeMB
        case serverFilename, downloadTaskID, dateDownloaded, sourceURL
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        trackID = try container.decode(String.self, forKey: .trackID)
        filename = try container.decode(String.self, forKey: .filename)
        localPath = try container.decode(String.self, forKey: .localPath)
        fileSizeMB = try container.decodeIfPresent(Double.self, forKey: .fileSizeMB) ?? 0
        serverFilename = try container.decodeIfPresent(String.self, forKey: .serverFilename) ?? ""
        downloadTaskID = try container.decodeIfPresent(String.self, forKey: .downloadTaskID)
        dateDownloaded = try container.decodeIfPresent(Date.self, forKey: .dateDownloaded) ?? Date()
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(trackID, forKey: .trackID)
        try container.encode(filename, forKey: .filename)
        try container.encode(localPath, forKey: .localPath)
        try container.encode(fileSizeMB, forKey: .fileSizeMB)
        try container.encode(serverFilename, forKey: .serverFilename)
        try container.encodeIfPresent(downloadTaskID, forKey: .downloadTaskID)
        try container.encode(dateDownloaded, forKey: .dateDownloaded)
        try container.encode(sourceURL, forKey: .sourceURL)
    }
}
