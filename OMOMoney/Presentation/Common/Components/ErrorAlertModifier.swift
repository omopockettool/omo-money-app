import SwiftUI

private struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.alert(LocalizationKey.General.error.localized, isPresented: $isPresented) {
            Button(LocalizationKey.General.ok.localized, role: .cancel) {
                onDismiss()
            }
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        message: String?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, message: message, onDismiss: onDismiss))
    }
}
