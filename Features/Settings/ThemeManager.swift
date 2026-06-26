import SwiftUI

@Observable
final class ThemeManager {
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var systemImage: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }
    }
    
    enum AccentColor: String, CaseIterable, Identifiable {
        case blue = "Blue"
        case purple = "Purple"
        case pink = "Pink"
        case red = "Red"
        case orange = "Orange"
        case green = "Green"
        case teal = "Teal"
        case mint = "Mint"
        
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .orange: return .orange
            case .green: return .green
            case .teal: return .teal
            case .mint: return .mint
            }
        }
    }
    
    var themeMode: ThemeMode {
        didSet { save() }
    }
    
    var accentColor: AccentColor {
        didSet { save() }
    }
    
    init() {
        let defaults = UserDefaults.standard
        if let rawMode = defaults.string(forKey: "theme_mode"),
           let mode = ThemeMode(rawValue: rawMode) {
            self.themeMode = mode
        } else {
            self.themeMode = .dark
        }
        
        if let rawAccent = defaults.string(forKey: "accent_color"),
           let accent = AccentColor(rawValue: rawAccent) {
            self.accentColor = accent
        } else {
            self.accentColor = .pink
        }
    }
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(themeMode.rawValue, forKey: "theme_mode")
        defaults.set(accentColor.rawValue, forKey: "accent_color")
    }
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
