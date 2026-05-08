import SwiftUI

/// Campo de texto con icono, botón de limpiar y límite de caracteres reutilizable.
/// El padre retiene el control del FocusState pasando su propio binding.
struct LimitedTextField<F: Hashable>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int = 30
    var axis: Axis = .horizontal
    var focusedField: FocusState<F?>.Binding
    let fieldValue: F

    private var isFocused: Bool { focusedField.wrappedValue == fieldValue }
    private var isMultiline: Bool { axis == .vertical }

    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, isMultiline ? 1 : 0)

            TextField(placeholder, text: $text, axis: axis)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .fontWeight(.semibold)
                .focused(focusedField, equals: fieldValue)
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.tertiaryLabel))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.top, isMultiline ? 1 : 0)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(AnimationHelper.quickEase, value: text.isEmpty)
            }
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                .stroke(isFocused ? Color(.systemGray3) : Color.clear, lineWidth: 1.5)
                .animation(AnimationHelper.formFocus, value: isFocused)
        )
    }
}
