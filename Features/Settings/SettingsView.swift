import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section {
                    Picker("Theme", selection: Binding(
                        get: { theme.themeMode },
                        set: { theme.themeMode = $0 }
                    )) {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
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
                                    .frame(width: 18, height: 18)
                                Text(accent.rawValue)
                            }
                            .tag(accent)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                // Playback
                Section {
                    Toggle("Gapless Playback", isOn: .constant(true))
                    
                    HStack {
                        Text("Crossfade")
                        Spacer()
                        Text("Off")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Playback")
                }
                
                // Downloads
                Section {
                    HStack {
                        Text("Audio Quality")
                        Spacer()
                        Text("Lossless")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Downloaded Files")
                        Spacer()
                        Text("\(DownloadManager.shared.allDownloadedFiles().count) tracks")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Downloads") {
                        // Implement clear downloads
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Downloads")
                }
                
                // Sleep Timer
                Section {
                    NavigationLink {
                        SleepTimerSettingView()
                    } label: {
                        HStack {
                            Label("Default Timer", systemImage: "moon.zzz")
                            Spacer()
                            Text("Off")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Sleep Timer")
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("Glitchi-Stream API")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("MeloPlayer Clone — Stream and download music via the Glitchi-Stream API.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SleepTimerSettingView: View {
    var body: some View {
        Form {
            Section {
                Text("Set a default sleep timer to automatically stop playback.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach([0, 5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                    HStack {
                        if minutes == 0 {
                            Text("Off")
                        } else if minutes < 60 {
                            Text("\(minutes) minutes")
                        } else {
                            Text("1 hour")
                        }
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.pink)
                            .opacity(0) // Placeholder
                    }
                }
            }
        }
        .navigationTitle("Sleep Timer")
    }
}
