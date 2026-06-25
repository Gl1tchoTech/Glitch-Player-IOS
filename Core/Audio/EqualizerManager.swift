import AVFoundation

@Observable
final class EqualizerManager {
    
    // MARK: - Presets
    
    enum Preset: String, CaseIterable, Identifiable {
        case flat = "Flat"
        case rock = "Rock"
        case pop = "Pop"
        case bass = "Bass Boost"
        case treble = "Treble Boost"
        case vocal = "Vocal Boost"
        case jazz = "Jazz"
        case classical = "Classical"
        case electronic = "Electronic"
        case hipHop = "Hip-Hop"
        case rnb = "R&B"
        case latin = "Latin"
        case metal = "Metal"
        case acoustic = "Acoustic"
        
        var id: String { rawValue }
        
        var bands: [Float] {
            switch self {
            case .flat:       return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            case .rock:       return [4, 3, 0, -1, -2, -2, 0, 2, 3, 4]
            case .pop:        return [0, 2, 4, 3, 0, -1, -1, 0, 1, 2]
            case .bass:       return [6, 5, 4, 3, 1, 0, 0, 0, 0, 0]
            case .treble:     return [0, 0, 0, 0, 0, 1, 2, 4, 5, 6]
            case .vocal:      return [0, 0, 3, 4, 3, 0, -1, -2, -1, 0]
            case .jazz:       return [3, 2, 1, 1, -1, -2, -1, 1, 2, 3]
            case .classical:  return [2, 2, 1, 0, -1, -1, 0, 1, 2, 2]
            case .electronic: return [5, 4, 0, -2, 1, 3, 4, 2, 1, 0]
            case .hipHop:     return [5, 4, 1, 2, -1, -1, 1, 2, 3, 4]
            case .rnb:        return [4, 3, 2, 1, 0, -1, 0, 1, 2, 1]
            case .latin:      return [3, 1, -1, -1, 0, 2, 3, 3, 2, 3]
            case .metal:      return [6, 5, 0, -2, 1, 2, 3, 3, 4, 5]
            case .acoustic:   return [3, 2, 2, 1, 0, 0, 0, 0, 0, 0]
            }
        }
        
        var systemImage: String {
            switch self {
            case .flat: return "equal.square"
            case .rock: return "guitars"
            case .pop: return "music.note"
            case .bass: return "speaker.wave.3"
            case .treble: return "waveform"
            case .vocal: return "mic"
            case .jazz: return "music.quarternote.3"
            case .classical: return "music.note.list"
            case .electronic: return "bolt"
            case .hipHop: return "music.mic"
            case .rnb: return "heart"
            case .latin: return "flame"
            case .metal: return "guitars.fill"
            case .acoustic: return "guitar"
            }
        }
    }
    
    // MARK: - Band Frequencies
    
    static let frequencies: [Int] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    static let frequencyLabels: [String] = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
    
    // Band gains in dB (-12 to +12)
    var bandGains: [Float] = Array(repeating: 0, count: 10) {
        didSet { applyGains() }
    }
    
    var preamp: Float = 0 {
        didSet { applyPreamp() }
    }
    
    var currentPreset: Preset = .flat {
        didSet { applyPreset(currentPreset) }
    }
    
    var isEnabled: Bool = true {
        didSet { applyEnabledState() }
    }
    
    private let eqUnit: AVAudioUnitEQ
    
    init(eqUnit: AVAudioUnitEQ) {
        self.eqUnit = eqUnit
        setupBands()
    }
    
    private func setupBands() {
        let bandTypes: [AVAudioUnitEQFilterType] = [
            .lowShelf,   // 32
            .parametric, // 64
            .parametric, // 125
            .parametric, // 250
            .parametric, // 500
            .parametric, // 1K
            .parametric, // 2K
            .parametric, // 4K
            .parametric, // 8K
            .highShelf   // 16K
        ]
        
        for (index, freq) in EqualizerManager.frequencies.enumerated() {
            let band = eqUnit.bands[index]
            band.filterType = bandTypes[index]
            band.frequency = Float(freq)
            band.bypass = false
            
            if bandTypes[index] == .parametric {
                band.bandwidth = 1.0
            }
        }
        
        applyPreset(.flat)
    }
    
    private func applyPreset(_ preset: Preset) {
        for (index, gain) in preset.bands.enumerated() {
            eqUnit.bands[index].gain = gain
            bandGains[index] = gain
        }
    }
    
    private func applyGains() {
        for (index, gain) in bandGains.enumerated() {
            eqUnit.bands[index].gain = gain
        }
    }
    
    private func applyPreamp() {
        eqUnit.globalGain = preamp
    }
    
    private func applyEnabledState() {
        eqUnit.bypass = !isEnabled
    }
    
    func resetToFlat() {
        currentPreset = .flat
        preamp = 0
    }
}
