import SwiftUI

struct SleepTimerSheet: View {
    @Environment(PlayerViewModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    
    let options = [0, 5, 10, 15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if player.sleepTimerMinutes > 0, let endDate = player.sleepTimerEndDate {
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)
                        
                        Text("Sleep Timer Active")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Music will stop at \(endDate, style: .time)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Button("Cancel Timer") {
                            player.cancelSleepTimer()
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pink)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 24)
                } else {
                    Text("Stop music after...")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.vertical, 16)
                    
                    List {
                        ForEach(options, id: \.self) { minutes in
                            Button(action: {
                                player.setSleepTimer(minutes: minutes)
                            }) {
                                HStack {
                                    if minutes == 0 {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.gray)
                                        Text("Off")
                                    } else {
                                        Image(systemName: "moon.zzz")
                                            .foregroundColor(.pink)
                                        Text(formatDuration(minutes))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        }
        return "\(hours)h \(mins)m"
    }
}
