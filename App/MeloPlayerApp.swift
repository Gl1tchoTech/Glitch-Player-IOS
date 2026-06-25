import SwiftUI
import SwiftData

@main
struct MeloPlayerApp: App {
    
    // MARK: - State Objects
    
    @State private var audioEngine = AudioEngineCoordinator()
    @State private var equalizerManager: EqualizerManager
    @State private var remoteCommandManager = RemoteCommandManager.shared
    @State private var sessionManager = AudioSessionManager.shared
    @State private var playerViewModel: PlayerViewModel
    @State private var themeManager = ThemeManager()
    @State private var libraryStore: LibraryStore
    @State private var browseViewModel = BrowseViewModel()
    
    // Shared model container
    let modelContainer: ModelContainer
    
    init() {
        // Phase 1: Initialize all stored properties (no self access)
        do {
            let schema = Schema([
                Track.self,
                Playlist.self,
                DownloadedTrack.self,
                PlayQueue.self
            ])
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        _equalizerManager = State(initialValue: EqualizerManager())
        
        let libraryStore = LibraryStore(modelContext: modelContainer.mainContext)
        _libraryStore = State(initialValue: libraryStore)
        
        _playerViewModel = State(initialValue: PlayerViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(audioEngine)
                .environment(equalizerManager)
                .environment(remoteCommandManager)
                .environment(playerViewModel)
                .environment(themeManager)
                .environment(browseViewModel)
                .environment(libraryStore)
                .modelContainer(modelContainer)
                .preferredColorScheme(themeManager.colorScheme)
                .tint(themeManager.accentColor.color)
                .onAppear {
                    // Enable background audio
                    sessionManager.enableBackgroundAudio()
                }
                .task {
                    // Wire up dependencies that require self access (Swift 6 init restriction)
                    sessionManager.configure()
                    remoteCommandManager.configure()
                    equalizerManager.wire(to: audioEngine.equalizer)
                    playerViewModel.configure(
                        audioEngine: audioEngine,
                        equalizerManager: equalizerManager,
                        remoteCommandManager: remoteCommandManager
                    )
                    playerViewModel.libraryStore = libraryStore
                }
        }
    }
}
