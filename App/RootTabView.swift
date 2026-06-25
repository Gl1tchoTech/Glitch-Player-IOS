import SwiftUI

struct RootTabView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(ThemeManager.self) private var theme
    
    @State private var selectedTab: Tab = .library
    
    enum Tab: String, CaseIterable {
        case library = "Library"
        case browse = "Browse"
        case search = "Search"
        case files = "Files"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .library: return "square.stack"
            case .browse: return "globe"
            case .search: return "magnifyingglass"
            case .files: return "folder"
            case .settings: return "gearshape"
            }
        }
        
        var filledIcon: String {
            switch self {
            case .library: return "square.stack.fill"
            case .browse: return "globe"
            case .search: return "magnifyingglass"
            case .files: return "folder.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tabItem {
                        Label(Tab.library.rawValue, systemImage: selectedTab == .library ? Tab.library.filledIcon : Tab.library.icon)
                    }
                    .tag(Tab.library)
                
                BrowseView()
                    .tabItem {
                        Label(Tab.browse.rawValue, systemImage: Tab.browse.icon)
                    }
                    .tag(Tab.browse)
                
                AudiusSearchView()
                    .tabItem {
                        Label(Tab.search.rawValue, systemImage: Tab.search.icon)
                    }
                    .tag(Tab.search)
                
                FolderBrowserView()
                    .tabItem {
                        Label(Tab.files.rawValue, systemImage: selectedTab == .files ? Tab.files.filledIcon : Tab.files.icon)
                    }
                    .tag(Tab.files)
                
                SettingsView()
                    .tabItem {
                        Label(Tab.settings.rawValue, systemImage: selectedTab == .settings ? Tab.settings.filledIcon : Tab.settings.icon)
                    }
                    .tag(Tab.settings)
            }
            
            // Mini Player overlay
            if player.currentTrack != nil {
                MiniPlayerView()
                    .environment(player)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: player.currentTrack != nil)
    }
}
