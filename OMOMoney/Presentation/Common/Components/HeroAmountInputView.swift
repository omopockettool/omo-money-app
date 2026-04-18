import SwiftUI

/// Hero amount input reutilizable. El padre retiene el control del FocusState
/// pasando su propio binding y el valor del campo que corresponde a este input.
struct HeroAmountInputView<F: Hashable>: View {
    @Binding var text: String
    let currencySymbol: String
    let onValidate: () -> Void
    var focusedField: FocusState<F?>.Binding
    let fieldValue: F
    var embedded: Bool = false

    private var isFocused: Bool { focusedField.wrappedValue == fieldValue }

    private var fontSize: CGFloat {
        let count = CGFloat(text.count)
        return max(30, 54 - (count / 9) * 24)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(text.isEmpty ? "0,00" : text)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? Color(.tertiaryLabel) : .primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: fontSize)
                    .animation(.snappy(duration: 0.2), value: text)

                if isFocused {
                    BlinkingCursor(height: fontSize * 0.78)
                        .foregroundStyle(.primary)
                        .transition(.opacity)
                }

                Text(currencySymbol)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: fieldValue)
                    .opacity(0)
                    .onChange(of: text) { _, _ in onValidate() }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .frame(maxWidth: .infinity)
        .padding(.vertical, embedded ? 12 : 18)
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .background(embedded ? Color.clear : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: embedded ? 0 : AppConstants.UserInterface.cornerRadius))
        .overlay {
            if !embedded {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                    .stroke(isFocused ? Color(.systemGray3) : Color.clear, lineWidth: 2.5)
                    .animation(AnimationHelper.formFocus, value: isFocused)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField.wrappedValue = fieldValue }
    }
}
