import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Spacer()
            Image(systemName: "sparkles.2")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(LocalizationKey.General.empty.localized)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
}
