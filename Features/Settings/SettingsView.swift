import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(PlayerViewModel.self) private var player
    
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
                                Capsule()
                                    .fill(accent.color)
                                    .frame(width: 24, height: 12)
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
                    Toggle("Gapless Playback", isOn: Binding(
                        get: { player.gaplessEnabled },
                        set: { player.gaplessEnabled = $0 }
                    ))
                    
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
                        for file in DownloadManager.shared.allDownloadedFiles() {
                            try? FileManager.default.removeItem(at: file)
                        }
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Downloads")
                }
                
                // Sleep Timer
                Section {
                    NavigationLink {
                        SleepTimerDefaultView()
                    } label: {
                        HStack {
                            Label("Default Timer", systemImage: "moon.zzz")
                            Spacer()
                            Text(sleepTimerLabel)
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
                        Text("API")
                        Spacer()
                        Text("Glitchi-Stream")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("ErrorStream — Stream and download music via the Glitchi-Stream API.")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var sleepTimerLabel: String {
        let mins = player.sleepTimerMinutes
        if mins == 0 { return "Off" }
        if mins < 60 { return "\(mins) min" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}

// MARK: - Sleep Timer Default

struct SleepTimerDefaultView: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    
    let options: [(Int, String)] = [
        (0, "Off"),
        (5, "5 minutes"),
        (10, "10 minutes"),
        (15, "15 minutes"),
        (30, "30 minutes"),
        (45, "45 minutes"),
        (60, "1 hour"),
        (90, "90 minutes"),
        (120, "2 hours"),
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(options, id: \.0) { mins, label in
                    Button(action: {
                        player.setSleepTimer(minutes: mins)
                        dismiss()
                    }) {
                        HStack {
                            Text(label)
                                .foregroundColor(.primary)
                            Spacer()
                            if player.sleepTimerMinutes == mins {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pink)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                }
            } header: {
                Text("Stop music after...")
            }
        }
        .navigationTitle("Sleep Timer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
