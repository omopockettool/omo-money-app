import SwiftUI

/// Button style that fires a rigid haptic on press-down and a soft haptic on release,
/// simulating the feel of pressing a physical button.
struct PressHapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.06 : 0))
                    .allowsHitTesting(false)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
    }
}
