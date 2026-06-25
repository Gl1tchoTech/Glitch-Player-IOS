import SwiftUI

struct EqualizerView: View {
    @Environment(EqualizerManager.self) private var eqManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preset Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EqualizerManager.Preset.allCases) { preset in
                            Button(action: { eqManager.currentPreset = preset }) {
                                VStack(spacing: 4) {
                                    Image(systemName: preset.systemImage)
                                        .font(.system(size: 20))
                                    Text(preset.rawValue)
                                        .font(.system(size: 11))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    eqManager.currentPreset == preset
                                        ? .pink.opacity(0.2)
                                        : .gray.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            eqManager.currentPreset == preset ? .pink : .clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .foregroundColor(eqManager.currentPreset == preset ? .pink : .primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // 10-Band Sliders
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        VStack(spacing: 6) {
                            Text(String(format: "%.0f", eqManager.bandGains[index]))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                            
                            VerticalSlider(
                                value: Binding(
                                    get: { Double(eqManager.bandGains[index]) },
                                    set: { eqManager.bandGains[index] = Float($0) }
                                ),
                                range: -12...12
                            )
                            .frame(height: 180)
                            
                            Text(EqualizerManager.frequencyLabels[index])
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Preamp
                HStack {
                    Text("Preamp")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Slider(value: Binding(
                        get: { Double(eqManager.preamp) },
                        set: { eqManager.preamp = Float($0) }
                    ), in: -12...12)
                    .frame(width: 160)
                    Text(String(format: "%.0f dB", eqManager.preamp))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Enable/Reset
                HStack(spacing: 16) {
                    Toggle("EQ Enabled", isOn: Binding(
                        get: { eqManager.isEnabled },
                        set: { eqManager.isEnabled = $0 }
                    ))
                    .font(.system(size: 14))
                    
                    Spacer()
                    
                    Button("Reset") {
                        eqManager.resetToFlat()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
            }
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Vertical Slider

struct VerticalSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink.opacity(0.5), .pink]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: geo.size.height * normalizedValue)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let ratio = 1 - min(max(gesture.location.y / geo.size.height, 0), 1)
                        value = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                    }
            )
        }
    }
    
    private var normalizedValue: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }
}
