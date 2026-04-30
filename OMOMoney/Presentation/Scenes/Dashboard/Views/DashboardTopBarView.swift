import SwiftUI

struct DashboardTopBarView: View {
    private enum DashboardRange: Hashable {
        case today
        case month
    }

    @Binding var showingFullMonth: Bool
    let hasItemsOutsideToday: Bool
    let onOpenSettings: () -> Void

    private var selectedRange: Binding<DashboardRange> {
        Binding(
            get: { showingFullMonth ? .month : .today },
            set: { newValue in
                withAnimation(AnimationHelper.quickSpring) {
                    showingFullMonth = (newValue == .month)
                }
            }
        )
    }

    var body: some View {
        HStack {
            if hasItemsOutsideToday {
                Picker("Dashboard Range", selection: selectedRange) {
                    Text(LocalizationKey.Dashboard.today.localized)
                        .tag(DashboardRange.today)
                    Text(LocalizationKey.Dashboard.thisMonth.localized)
                        .tag(DashboardRange.month)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
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
