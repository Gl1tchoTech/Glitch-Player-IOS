import Foundation

enum AudioSource: Equatable {
    case localFile(url: URL)
    case remoteStream(url: URL)
    case downloadedTrack(trackID: String, localURL: URL)
    case apiStream(filename: String)
    case apiPreview(trackID: String)
    
    var url: URL? {
        switch self {
        case .localFile(let url),
             .remoteStream(let url),
             .downloadedTrack(_, let url):
            return url
        case .apiStream(let filename):
            return URL(string: "https://glitchi-stream.onrender.com/files/stream?filename=\(filename)")
        case .apiPreview(let trackID):
            return URL(string: "https://glitchi-stream.onrender.com/files/stream/preview/\(trackID)")
        }
    }
    
    var displayName: String {
        switch self {
        case .localFile: return "Local File"
        case .remoteStream: return "Streaming"
        case .downloadedTrack: return "Downloaded"
        case .apiStream: return "API Stream"
        case .apiPreview: return "Preview"
        }
    }
    
    var isLocal: Bool {
        switch self {
        case .localFile, .downloadedTrack: return true
        default: return false
        }
    }
    
    var isRemote: Bool {
        return !isLocal
    }
}
