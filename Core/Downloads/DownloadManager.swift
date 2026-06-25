import Foundation
import SwiftData

@Observable
final class DownloadManager: NSObject {
    
    static let shared = DownloadManager()
    
    private var urlSession: URLSession!
    private var activeDownloads: [String: DownloadTaskInfo] = [:]
    private let downloadQueue = OperationQueue()
    private let fileManager = FileManager.default
    
    var onProgress: ((String, Double) -> Void)?
    var onCompleted: ((String, URL) -> Void)?
    var onError: ((String, Error) -> Void)?
    
    var downloadDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let meloDir = docs.appendingPathComponent("MeloMusic")
        try? fileManager.createDirectory(at: meloDir, withIntermediateDirectories: true)
        return meloDir
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.meloplayer.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: downloadQueue)
    }
    
    // MARK: - Download from API
    
    func downloadFromServer(filename: String, trackID: String) async throws {
        guard let url = URL(string: "https://glitchi-stream.onrender.com/files/download/\(filename)") else {
            throw DownloadError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let downloadTask = urlSession.downloadTask(with: request)
        downloadTask.taskDescription = trackID
        
        activeDownloads[trackID] = DownloadTaskInfo(
            task: downloadTask,
            trackID: trackID,
            filename: filename
        )
        
        downloadTask.resume()
    }
    
    func downloadTrack(spotifyURL: String, trackID: String) async throws {
        // Step 1: Start download task on server
        let api = GlitchiAPIClient.shared
        let response = try await api.startDownload(url: spotifyURL, services: ["qobuz", "tidal"])
        
        guard let taskID = response.taskID else {
            throw DownloadError.noTaskID
        }
        
        // Step 2: Poll for completion
        while true {
            let progress = try await api.downloadProgress(taskID: taskID)
            
            if progress.status == "completed", let filename = progress.filename {
                // Step 3: Download the file from server
                try await downloadFromServer(filename: filename, trackID: trackID)
                break
            } else if progress.status == "failed" || progress.error != nil {
                throw DownloadError.serverError(progress.error ?? "Unknown error")
            }
            
            // Report progress
            onProgress?(trackID, progress.progress ?? 0)
            
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
    
    // MARK: - File Management
    
    func localFileURL(for filename: String) -> URL {
        return downloadDirectory.appendingPathComponent(filename)
    }
    
    func fileExists(filename: String) -> Bool {
        return fileManager.fileExists(atPath: localFileURL(for: filename).path)
    }
    
    func deleteLocalFile(filename: String) throws {
        try fileManager.removeItem(at: localFileURL(for: filename))
        activeDownloads.removeValue(forKey: filename)
    }
    
    func allDownloadedFiles() -> [URL] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: downloadDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return [] }
        
        return contents.filter {
            let ext = $0.pathExtension.lowercased()
            return ["mp3", "flac", "m4a", "wav", "aac", "ogg"].contains(ext)
        }
    }
    
    func fileSize(for filename: String) -> Double {
        let url = localFileURL(for: filename)
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return 0 }
        return Double(size) / 1_048_576 // MB
    }
}

// MARK: - URL Session Delegate

extension DownloadManager: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let trackID = downloadTask.taskDescription else { return }
        
        do {
            let destURL = downloadDirectory.appendingPathComponent("\(trackID).mp3")
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.moveItem(at: location, to: destURL)
            
            DispatchQueue.main.async { [weak self] in
                self?.activeDownloads.removeValue(forKey: trackID)
                self?.onCompleted?(trackID, destURL)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onError?(trackID, error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0,
              let trackID = downloadTask.taskDescription else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { [weak self] in
            self?.onProgress?(trackID, progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, let trackID = task.taskDescription {
            DispatchQueue.main.async { [weak self] in
                self?.onError?(trackID, error)
            }
        }
    }
}

// MARK: - Supporting Types

struct DownloadTaskInfo {
    let task: URLSessionDownloadTask
    let trackID: String
    let filename: String
    var progress: Double = 0
}

enum DownloadError: LocalizedError {
    case invalidURL
    case noTaskID
    case serverError(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid download URL"
        case .noTaskID: return "No task ID returned from server"
        case .serverError(let msg): return "Server error: \(msg)"
        case .fileNotFound: return "Downloaded file not found"
        }
    }
}
