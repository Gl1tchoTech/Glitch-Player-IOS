import Foundation
import SwiftData

@Model
final class Playlist: Identifiable, Codable {
    var id: String
    var name: String
    var playlistDescription: String
    var imageURL: String
    var spotifyURL: String
    var tracksCount: Int
    var owner: String
    
    // Local
    var isUserCreated: Bool
    var dateCreated: Date
    var dateModified: Date
    
    @Relationship(deleteRule: .cascade)
    var tracks: [Track] = []
    
    var coverImageData: Data?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        playlistDescription: String = "",
        imageURL: String = "",
        spotifyURL: String = "",
        tracksCount: Int = 0,
        owner: String = "",
        isUserCreated: Bool = false,
        tracks: [Track] = []
    ) {
        self.id = id
        self.name = name
        self.playlistDescription = playlistDescription
        self.imageURL = imageURL
        self.spotifyURL = spotifyURL
        self.tracksCount = tracksCount
        self.owner = owner
        self.isUserCreated = isUserCreated
        self.dateCreated = Date()
        self.dateModified = Date()
        self.tracks = tracks
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case playlistDescription = "description"
        case imageURL = "image_url"
        case spotifyURL = "url"
        case tracksCount = "tracks_count"
        case owner
        case isUserCreated, dateCreated, dateModified, tracks
        case coverImageData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        playlistDescription = try container.decodeIfPresent(String.self, forKey: .playlistDescription) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL) ?? ""
        spotifyURL = try container.decodeIfPresent(String.self, forKey: .spotifyURL) ?? ""
        tracksCount = try container.decodeIfPresent(Int.self, forKey: .tracksCount) ?? 0
        owner = try container.decodeIfPresent(String.self, forKey: .owner) ?? ""
        isUserCreated = try container.decodeIfPresent(Bool.self, forKey: .isUserCreated) ?? false
        dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified) ?? Date()
        tracks = try container.decodeIfPresent([Track].self, forKey: .tracks) ?? []
        coverImageData = try container.decodeIfPresent(Data.self, forKey: .coverImageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(playlistDescription, forKey: .playlistDescription)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(spotifyURL, forKey: .spotifyURL)
        try container.encode(tracksCount, forKey: .tracksCount)
        try container.encode(owner, forKey: .owner)
        try container.encode(isUserCreated, forKey: .isUserCreated)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(dateModified, forKey: .dateModified)
        try container.encode(tracks, forKey: .tracks)
        try container.encodeIfPresent(coverImageData, forKey: .coverImageData)
    }
}
