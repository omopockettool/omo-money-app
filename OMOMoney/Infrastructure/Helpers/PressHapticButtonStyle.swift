import SwiftUI

/// Button style that fires a rigid haptic on press-down and a soft haptic on release,
/// simulating the feel of pressing a physical button.
struct PressHapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
    }
}
