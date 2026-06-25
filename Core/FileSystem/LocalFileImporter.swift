import Foundation
import SwiftData
import UniformTypeIdentifiers
import AVFoundation
import UIKit

@Observable
final class LocalFileImporter {
    
    static let shared = LocalFileImporter()
    private let fileManager = FileManager.default
    
    var importedFiles: [ImportedFile] = []
    
    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var meloMusicDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("MeloMusic")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    // MARK: - Import
    
    func importFile(from sourceURL: URL) throws -> ImportedFile {
        let filename = sourceURL.lastPathComponent
        let destURL = meloMusicDirectory.appendingPathComponent(filename)
        
        // Remove if exists
        try? fileManager.removeItem(at: destURL)
        
        // Copy file
        try fileManager.copyItem(at: sourceURL, to: destURL)
        
        let metadata = try extractMetadata(from: destURL)
        let imported = ImportedFile(
            id: UUID().uuidString,
            filename: filename,
            localURL: destURL,
            title: metadata.title ?? filename.replacingOccurrences(of: ".\(sourceURL.pathExtension)", with: ""),
            artist: metadata.artist ?? "Unknown Artist",
            album: metadata.album ?? "Unknown Album",
            duration: metadata.duration,
            fileSizeMB: Double((try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) / 1_048_576,
            source: .localFile(url: destURL)
        )
        
        importedFiles.append(imported)
        return imported
    }
    
    func importFromSecurityScopedURL(_ url: URL) throws -> ImportedFile {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        return try importFile(from: url)
    }
    
    // MARK: - Scanning
    
    func scanLocalFiles() -> [ImportedFile] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: meloMusicDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return [] }
        
        let audioURLs = contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ["mp3", "flac", "m4a", "wav", "aac", "ogg", "alac", "aiff"].contains(ext)
        }
        
        return audioURLs.compactMap { url -> ImportedFile? in
            guard let metadata = try? extractMetadata(from: url) else { return nil }
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            
            return ImportedFile(
                id: UUID().uuidString,
                filename: url.lastPathComponent,
                localURL: url,
                title: metadata.title ?? url.deletingPathExtension().lastPathComponent,
                artist: metadata.artist ?? "Unknown Artist",
                album: metadata.album ?? "Unknown Album",
                duration: metadata.duration,
                fileSizeMB: Double(fileSize) / 1_048_576,
                source: .localFile(url: url)
            )
        }
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from url: URL) throws -> AudioMetadata {
        let playerItem = AVPlayerItem(url: url)
        let metadataList = playerItem.asset.commonMetadata
        
        var metadata = AudioMetadata()
        
        for item in metadataList {
            switch item.commonKey {
            case .commonKeyTitle:
                metadata.title = item.stringValue
            case .commonKeyArtist:
                metadata.artist = item.stringValue
            case .commonKeyAlbumName:
                metadata.album = item.stringValue
            case .commonKeyArtwork:
                metadata.artworkData = item.dataValue
            default:
                break
            }
        }
        
        metadata.duration = CMTimeGetSeconds(playerItem.asset.duration)
        if metadata.duration.isNaN { metadata.duration = 0 }
        
        return metadata
    }
    
    // MARK: - Delete
    
    func deleteFile(_ file: ImportedFile) throws {
        try fileManager.removeItem(at: file.localURL)
        importedFiles.removeAll { $0.id == file.id }
    }
}

// MARK: - Types

struct ImportedFile: Identifiable {
    let id: String
    let filename: String
    let localURL: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let fileSizeMB: Double
    let source: AudioSource
    
    var durationFormatted: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    var artwork: UIImage? {
        // Try to extract artwork from file
        let asset = AVAsset(url: localURL)
        for item in asset.commonMetadata {
            if item.commonKey == .commonKeyArtwork, let data = item.dataValue {
                return UIImage(data: data)
            }
        }
        return nil
    }
}

struct AudioMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var artworkData: Data?
    var duration: TimeInterval = 0
}

