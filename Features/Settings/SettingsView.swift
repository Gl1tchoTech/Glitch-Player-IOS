import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { theme.themeMode },
                        set: { theme.themeMode = $0 }
                    )) {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    Picker("Accent Color", selection: Binding(
                        get: { theme.accentColor },
                        set: { theme.accentColor = $0 }
                    )) {
                        ForEach(ThemeManager.AccentColor.allCases) { accent in
                            HStack {
                                Circle()
                                    .fill(accent.color)
                                    .frame(width: 16, height: 16)
                                Text(accent.rawValue)
                            }
                            .tag(accent)
                        }
                    }
                }
                
                // Playback
                Section("Playback") {
                    Toggle("Gapless Playback", isOn: .constant(true))
                    Stepper("Crossfade: 0s", value: .constant(0), in: 0...12)
                }
                
                // Downloads
                Section("Downloads") {
                    HStack {
                        Text("Audio Quality")
                        Spacer()
                        Text("Lossless")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Downloaded Files")
                        Spacer()
                        Text("\(DownloadManager.shared.allDownloadedFiles().count) tracks")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Clear Downloads") {
                        // Implement clear downloads
                    }
                    .foregroundColor(.red)
                }
                
                // Sleep Timer
                Section("Sleep Timer") {
                    NavigationLink(destination: SleepTimerSettingView()) {
                        HStack {
                            Label("Default Timer", systemImage: "moon.zzz")
                            Spacer()
                            Text("Off")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink(destination: Text("MeloPlayer Clone - Stream and download music via Glitchi-Stream API").padding()) {
                        Text("About MeloPlayer")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SleepTimerSettingView: View {
    var body: some View {
        List {
            Text("Set default sleep timer duration")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .navigationTitle("Sleep Timer")
    }
}
