import SwiftUI

/// Campo de texto con icono, botón de limpiar y límite de caracteres reutilizable.
/// El padre retiene el control del FocusState pasando su propio binding.
struct LimitedTextField<F: Hashable>: View {
    enum Style {
        case groupedCard
        case formRow
        case embedded
    }

    let icon: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int = 30
    var axis: Axis = .horizontal
    var style: Style = .groupedCard
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    var focusedField: FocusState<F?>.Binding
    let fieldValue: F

    private var isFocused: Bool { focusedField.wrappedValue == fieldValue }
    private var isMultiline: Bool { axis == .vertical }
    private var usesGroupedCardChrome: Bool { style == .groupedCard }
    private var usesEmbeddedChrome: Bool { style == .embedded }
    private var limitedText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = String(newValue.prefix(maxLength))
            }
        )
    }

    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, isMultiline ? 1 : 0)

            TextField(placeholder, text: limitedText, axis: axis)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .fontWeight(.semibold)
                .focused(focusedField, equals: fieldValue)
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit?()
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
        .padding(usesEmbeddedChrome ? 0 : AppConstants.UserInterface.padding)
        .background(backgroundView)
        .clipShape(clipShape)
        .overlay(overlayView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if usesGroupedCardChrome {
            Color(.secondarySystemGroupedBackground)
        } else if usesEmbeddedChrome {
            Color.clear
        } else {
            Color.clear
        }
    }

    private var clipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: usesGroupedCardChrome ? AppConstants.UserInterface.cornerRadius : 12)
    }

    @ViewBuilder
    private var overlayView: some View {
        if usesGroupedCardChrome {
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                .stroke(isFocused ? Color(.systemGray3) : Color.clear, lineWidth: 1.5)
                .animation(AnimationHelper.formFocus, value: isFocused)
        } else if usesEmbeddedChrome {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color(.systemGray4) : Color.clear, lineWidth: 1)
                .animation(AnimationHelper.formFocus, value: isFocused)
        }
    }
}
