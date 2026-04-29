import SwiftUI

struct DashboardTopBarView: View {
    @Binding var showingFullMonth: Bool
    let hasItemsOutsideToday: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        HStack {
            if hasItemsOutsideToday {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(AnimationHelper.quickSpring) { showingFullMonth = false }
                    } label: {
                        Label(LocalizationKey.Dashboard.today.localized, systemImage: "sparkles")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(!showingFullMonth ? Color.accentColor : Color.clear)
                            .foregroundStyle(!showingFullMonth ? Color.white : Color.secondary)
                            .clipShape(Capsule())
                    }
                    Button {
                        withAnimation(AnimationHelper.quickSpring) { showingFullMonth = true }
                    } label: {
                        Text(LocalizationKey.Dashboard.thisMonth.localized)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(showingFullMonth ? Color.accentColor : Color.clear)
                            .foregroundStyle(showingFullMonth ? Color.white : Color.secondary)
                            .clipShape(Capsule())
                    }
                }
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
                .animation(AnimationHelper.quickSpring, value: showingFullMonth)
            }

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }
}
