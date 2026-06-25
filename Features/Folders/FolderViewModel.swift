import SwiftUI
import UniformTypeIdentifiers

@Observable
final class FolderViewModel {
    
    private let importer = LocalFileImporter.shared
    let fileManager = FileManager.default
    
    var currentFolder: URL
    var contents: [FileItemView] = []
    var breadcrumbs: [URL] = []
    var isImporting: Bool = false
    var selectedFile: URL?
    
    init() {
        self.currentFolder = importer.meloMusicDirectory
        self.breadcrumbs = [currentFolder]
        refresh()
    }
    
    // MARK: - Navigation
    
    func navigateTo(_ folder: URL) {
        currentFolder = folder
        if !breadcrumbs.contains(folder) {
            breadcrumbs.append(folder)
        } else {
            breadcrumbs = Array(breadcrumbs.prefix(through: breadcrumbs.firstIndex(of: folder)!))
        }
        refresh()
    }
    
    func navigateUp() {
        guard breadcrumbs.count > 1 else { return }
        breadcrumbs.removeLast()
        currentFolder = breadcrumbs.last!
        refresh()
    }
    
    func navigateToBreadcrumb(at index: Int) {
        guard index < breadcrumbs.count else { return }
        currentFolder = breadcrumbs[index]
        breadcrumbs = Array(breadcrumbs.prefix(through: index))
        refresh()
    }
    
    // MARK: - File Operations
    
    func refresh() {
        do {
            let items = try fileManager.contentsOfDirectory(
                at: currentFolder,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            )
            
            // Sort: folders first, then files alphabetically
            contents = items.compactMap { url in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                
                let ext = url.pathExtension.lowercased()
                let isAudio = ["mp3", "flac", "m4a", "wav", "aac", "ogg", "alac", "aiff"].contains(ext)
                
                return FileItemView(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: isDir,
                    isAudio: isAudio,
                    fileSize: Int64(size),
                    modificationDate: date,
                    `extension`: ext
                )
            }.sorted { a, b in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        } catch {
            contents = []
        }
    }
    
    func importFromPicker(result: Result<[URL], Error>) {
        isImporting = true
        defer { isImporting = false }
        
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    _ = try importer.importFromSecurityScopedURL(url)
                } catch {
                    print("[FolderViewModel] Import failed: \(error)")
                }
            }
        case .failure(let error):
            print("[FolderViewModel] File picker error: \(error)")
        }
        
        refresh()
    }
    
    func deleteFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
        refresh()
    }
    
    func renameFile(at url: URL, to newName: String) throws {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try fileManager.moveItem(at: url, to: newURL)
        refresh()
    }
}

struct FileItemView: Identifiable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isAudio: Bool
    let fileSize: Int64
    let modificationDate: Date
    let `extension`: String
    
    var id: String { url.absoluteString }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var systemImage: String {
        if isDirectory { return "folder.fill" }
        switch `extension` {
        case "mp3", "m4a", "aac", "ogg": return "music.note"
        case "flac", "alac": return "waveform"
        case "wav": return "waveform.path"
        default: return "doc"
        }
    }
    
    var iconColor: Color {
        if isDirectory { return .blue }
        if isAudio { return .pink }
        return .gray
    }
}
