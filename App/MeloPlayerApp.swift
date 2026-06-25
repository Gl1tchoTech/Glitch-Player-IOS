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
        // Configure audio session
        sessionManager.configure()
        remoteCommandManager.configure()
        
        // Connect equalizer manager to engine
        let eq = EqualizerManager(eqUnit: audioEngine.equalizer)
        _equalizerManager = State(initialValue: eq)
        
        // Create SwiftData container
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
        
        // Create player view model and wire up library store
        let libraryStore = LibraryStore(modelContext: modelContainer.mainContext)
        _libraryStore = State(initialValue: libraryStore)
        
        let playerVM = PlayerViewModel(
            audioEngine: audioEngine,
            equalizerManager: eq,
            remoteCommandManager: remoteCommandManager
        )
        playerVM.libraryStore = libraryStore
        _playerViewModel = State(initialValue: playerVM)
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
        }
    }
}
