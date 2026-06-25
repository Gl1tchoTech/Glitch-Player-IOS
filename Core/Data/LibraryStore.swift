import Foundation
import SwiftData

@Observable
final class LibraryStore {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Tracks
    
    func allTracks() throws -> [Track] {
        let descriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func favoriteTracks() throws -> [Track] {
        let predicate = #Predicate<Track> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func downloadedTracks() throws -> [Track] {
        let predicate = #Predicate<Track> { $0.isDownloaded == true }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.downloadDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func localTracks() throws -> [Track] {
        let predicate = #Predicate<Track> { $0.source == "local" }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    func streamedTracks() throws -> [Track] {
        let predicate = #Predicate<Track> { $0.source == "stream" }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func searchTracks(query: String) throws -> [Track] {
        let predicate = #Predicate<Track> {
            $0.name.localizedStandardContains(query) ||
            $0.artists.localizedStandardContains(query) ||
            $0.album.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Albums
    
    func allAlbums() throws -> [String] {
        let tracks = try allTracks()
        var seen = Set<String>()
        return tracks.compactMap { track -> String? in
            let album = track.album
            guard !album.isEmpty, !seen.contains(album) else { return nil }
            seen.insert(album)
            return album
        }
    }
    
    func tracks(forAlbum album: String) throws -> [Track] {
        let predicate = #Predicate<Track> { $0.album == album }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Artists
    
    func allArtists() throws -> [String] {
        let tracks = try allTracks()
        var seen = Set<String>()
        return tracks.compactMap { track -> String? in
            let artist = track.artists
            guard !artist.isEmpty, !seen.contains(artist) else { return nil }
            seen.insert(artist)
            return artist
        }
    }
    
    func tracks(forArtist artist: String) throws -> [Track] {
        let predicate = #Predicate<Track> { $0.artists.localizedStandardContains(artist) }
        let descriptor = FetchDescriptor<Track>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Playlists
    
    func allPlaylists() throws -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.dateModified, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func userPlaylists() throws -> [Playlist] {
        let predicate = #Predicate<Playlist> { $0.isUserCreated == true }
        let descriptor = FetchDescriptor<Playlist>(predicate: predicate, sortBy: [SortDescriptor(\.dateModified, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func createPlaylist(name: String, description: String = "") -> Playlist {
        let playlist = Playlist(name: name, playlistDescription: description, isUserCreated: true)
        modelContext.insert(playlist)
        return playlist
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        modelContext.delete(playlist)
    }
    
    func addTrack(_ track: Track, to playlist: Playlist) {
        if !playlist.tracks.contains(where: { $0.id == track.id }) {
            playlist.tracks.append(track)
            playlist.tracksCount = playlist.tracks.count
            playlist.dateModified = Date()
        }
    }
    
    func removeTrack(_ track: Track, from playlist: Playlist) {
        playlist.tracks.removeAll { $0.id == track.id }
        playlist.tracksCount = playlist.tracks.count
        playlist.dateModified = Date()
    }
    
    // MARK: - Track Management
    
    func addTrack(_ track: Track) {
        // Check for duplicates
        let predicate = #Predicate<Track> { $0.id == track.id }
        let descriptor = FetchDescriptor<Track>(predicate: predicate)
        if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
            modelContext.insert(track)
        } else if track.id.isEmpty {
            modelContext.insert(track)
        }
    }
    
    func toggleFavorite(_ track: Track) {
        track.isFavorite.toggle()
    }
    
    func deleteTrack(_ track: Track) {
        modelContext.delete(track)
    }
    
    func updatePlayCount(_ track: Track) {
        track.playCount += 1
    }
    
    func updateLastPosition(_ track: Track, position: Double) {
        track.lastPosition = position
    }
    
    // MARK: - PlayQueue
    
    func currentQueue() throws -> PlayQueue {
        let descriptor = FetchDescriptor<PlayQueue>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let queue = PlayQueue()
        modelContext.insert(queue)
        return queue
    }
    
    func save() throws {
        try modelContext.save()
    }
}
