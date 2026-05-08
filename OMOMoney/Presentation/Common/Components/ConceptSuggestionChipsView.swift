import SwiftUI

struct ConceptSuggestionChipsView: View {
    let suggestions: [ConceptSuggestion]
    let onSelect: (ConceptSuggestion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.description) { suggestion in
                    let color = Color(hex: suggestion.category.color) ?? Color(.systemGray4)
                    Button {
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion.description)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(color)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressHapticButtonStyle())
                }
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 4)
        }
    }
}
