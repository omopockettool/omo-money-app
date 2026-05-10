import SwiftUI

struct DashboardNoResultsState: View {
    private let emptyStateMinHeight: CGFloat = 360

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(.secondary)

                Text(LocalizationKey.Dashboard.noMatchesTitle.localized)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(LocalizationKey.Dashboard.noMatchesMessage.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .frame(maxWidth: .infinity)
        .frame(minHeight: emptyStateMinHeight)
    }
}
