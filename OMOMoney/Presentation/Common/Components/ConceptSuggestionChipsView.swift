import SwiftUI

struct ConceptSuggestionChipsView: View {
    let suggestions: [String]
    let categoryColor: Color
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(categoryColor)
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
