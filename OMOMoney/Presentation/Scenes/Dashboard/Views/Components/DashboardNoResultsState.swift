import SwiftUI

struct DashboardNoResultsState: View {
    var body: some View {
        VStack {
            Spacer(minLength: 0)

            ViewThatFits(in: .vertical) {
                stateLayout(isCompact: false)
                stateLayout(isCompact: true)
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func stateLayout(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 10 : AppConstants.UserInterface.padding) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: isCompact ? 30 : 36, weight: .regular))
                .foregroundStyle(.secondary)

            Text(LocalizationKey.Dashboard.noMatchesTitle.localized)
                .font(.headline)
                .foregroundStyle(.secondary)

            if !isCompact {
                Text(LocalizationKey.Dashboard.noMatchesMessage.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
