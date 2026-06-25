import SwiftUI
import AVKit

struct AirPlayRouteButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = .systemPink
        view.tintColor = .white.withAlphaComponent(0.6)
        view.prioritizesVideoDevices = false
        return view
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
