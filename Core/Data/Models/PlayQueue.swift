import Foundation
import SwiftData

@Model
final class PlayQueue: Identifiable, Codable {
    var id: String
    
    // Current queue
    @Relationship(deleteRule: .nullify)
    var queuedTracks: [Track] = []
    
    // Current index in queue
    var currentIndex: Int
    
    // Playback modes
    var isShuffled: Bool
    var repeatMode: RepeatMode
    
    // Shuffled order indices
    var shuffledIndices: [Int] = []
    
    var lastUpdated: Date
    
    init(
        id: String = "mainQueue",
        queuedTracks: [Track] = [],
        currentIndex: Int = 0,
        isShuffled: Bool = false,
        repeatMode: RepeatMode = .off
    ) {
        self.id = id
        self.queuedTracks = queuedTracks
        self.currentIndex = currentIndex
        self.isShuffled = isShuffled
        self.repeatMode = repeatMode
        self.lastUpdated = Date()
    }
    
    // MARK: - Computed
    
    var currentTrack: Track? {
        guard !queuedTracks.isEmpty,
              currentIndex >= 0,
              currentIndex < queuedTracks.count else { return nil }
        
        let actualIndex = isShuffled
            ? (shuffledIndices.indices.contains(currentIndex) ? shuffledIndices[currentIndex] : currentIndex)
            : currentIndex
        guard actualIndex >= 0, actualIndex < queuedTracks.count else { return nil }
        return queuedTracks[actualIndex]
    }
    
    var hasNextTrack: Bool {
        guard !queuedTracks.isEmpty else { return false }
        if repeatMode == .one || repeatMode == .all { return true }
        return currentIndex < queuedTracks.count - 1
    }
    
    var hasPreviousTrack: Bool {
        return currentIndex > 0
    }
    
    func nextTrack() -> Bool {
        guard !queuedTracks.isEmpty else { return false }
        
        if currentIndex < queuedTracks.count - 1 {
            currentIndex += 1
            return true
        } else if repeatMode == .all {
            currentIndex = 0
            reshuffleIfNeeded()
            return true
        }
        return false
    }
    
    func previousTrack() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            return true
        } else if repeatMode == .all {
            currentIndex = queuedTracks.count - 1
            return true
        }
        return false
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            reshuffleIfNeeded()
        }
    }
    
    func reshuffleIfNeeded() {
        guard !queuedTracks.isEmpty, isShuffled else { return }
        var indices = Array(0..<queuedTracks.count)
        // Fisher-Yates shuffle excluding current
        if let currentIdx = indices.firstIndex(of: currentIndex) {
            indices.remove(at: currentIdx)
        }
        indices.shuffle()
        shuffledIndices = [currentIndex] + indices
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, queuedTracks, currentIndex, isShuffled, repeatMode
        case shuffledIndices, lastUpdated
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        queuedTracks = try container.decodeIfPresent([Track].self, forKey: .queuedTracks) ?? []
        currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        isShuffled = try container.decodeIfPresent(Bool.self, forKey: .isShuffled) ?? false
        repeatMode = try container.decodeIfPresent(RepeatMode.self, forKey: .repeatMode) ?? .off
        shuffledIndices = try container.decodeIfPresent([Int].self, forKey: .shuffledIndices) ?? []
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(queuedTracks, forKey: .queuedTracks)
        try container.encode(currentIndex, forKey: .currentIndex)
        try container.encode(isShuffled, forKey: .isShuffled)
        try container.encode(repeatMode, forKey: .repeatMode)
        try container.encode(shuffledIndices, forKey: .shuffledIndices)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
}

// MARK: - RepeatMode

enum RepeatMode: String, Codable, CaseIterable {
    case off
    case all
    case one
    
    var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
    
    var next: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }
}
