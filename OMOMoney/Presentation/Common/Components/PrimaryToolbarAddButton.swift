import SwiftUI

struct PrimaryToolbarAddButton: View {
    let isDisabled: Bool
    let action: () -> Void

    init(
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(isDisabled ? .gray : .white)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
