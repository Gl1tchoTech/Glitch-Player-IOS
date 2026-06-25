import SwiftUI

@Observable
final class ThemeManager {
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
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
    
    var themeMode: ThemeMode = .dark
    var accentColor: AccentColor = .pink
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var backgroundColor: Color {
        themeMode == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .systemBackground)
    }
    
    var secondaryBackground: Color {
        themeMode == .dark ? Color(uiColor: .secondarySystemBackground) : Color(uiColor: .secondarySystemBackground)
    }
    
    var isDarkMode: Bool {
        if themeMode == .dark { return true }
        if themeMode == .light { return false }
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}
