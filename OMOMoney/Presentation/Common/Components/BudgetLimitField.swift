import SwiftUI

/// Reusable budget limit input field with section label, accent icon, clear button, and keyboard Done toolbar.
struct BudgetLimitField: View {
    @Binding var text: String
    let accentColor: Color
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationKey.Category.limit.localized)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)

                TextField(LocalizationKey.Category.noLimit.localized, text: $text)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(LocalizationKey.General.done.localized) {
                                isFocused = false
                            }
                            .fontWeight(.semibold)
                        }
                    }

                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
    }
}
