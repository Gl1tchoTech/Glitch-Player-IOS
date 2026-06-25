import SwiftUI

// MARK: - Custom Slider

struct CustomSlider: View {
    @Binding var value: TimeInterval
    let range: ClosedRange<TimeInterval>
    var onEditingChanged: ((Bool) -> Void)? = nil
    
    @State private var isDragging: Bool = false
    @State private var dragValue: TimeInterval = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                
                // Track fill
                Capsule()
                    .fill(.white)
                    .frame(width: fillWidth(geo.size.width), height: 4)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .offset(x: fillWidth(geo.size.width) - 8)
                    .scaleEffect(isDragging ? 1.3 : 1.0)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            dragValue = value
                            onEditingChanged?(true)
                        }
                        let ratio = min(max(gesture.location.x / geo.size.width, 0), 1)
                        value = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged?(false)
                    }
            )
            .animation(.spring(response: 0.2), value: isDragging)
        }
    }
    
    private func fillWidth(_ totalWidth: CGFloat) -> CGFloat {
        let ratio = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * CGFloat(max(0, min(1, ratio)))
    }
}

// MARK: - Format Time Helper

func formatTime(_ time: TimeInterval) -> String {
    guard time.isFinite && !time.isNaN else { return "0:00" }
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
