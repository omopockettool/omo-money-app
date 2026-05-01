import SwiftUI

struct DashboardLoadingState: View {
    var body: some View {
        Color(.systemBackground).ignoresSafeArea()
    }
}

struct DashboardErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(LocalizationKey.General.error.localized)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizationKey.General.retry.localized, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardChangingGroupOverlay: View {
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    Text(LocalizationKey.Dashboard.changingGroup.localized)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
    }
}

struct DashboardHeroSection: View {
    let heroIsSuccess: Bool
    let lastAddedDescription: String
    let showingFullMonth: Bool
    let monthTotal: String
    let todayTotal: String
    let onAddExpense: () -> Void

    var body: some View {
        TotalSpentCardView(
            label: heroIsSuccess ? lastAddedDescription : (showingFullMonth ? LocalizationKey.Dashboard.costThisMonth.localized : LocalizationKey.Dashboard.costToday.localized),
            totalAmount: showingFullMonth ? monthTotal : todayTotal,
            onAddExpense: onAddExpense,
            isSuccess: heroIsSuccess
        )
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.padding)
        .padding(.bottom, 4)
        .animation(AnimationHelper.smoothSpring, value: showingFullMonth)
    }
}

struct DashboardBottomInset: View {
    let heroSection: AnyView
    let bottomBar: AnyView

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            bottomBar
        }
        .background {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .bottom)

                Rectangle()
                    .fill(Color(.separator).opacity(0.22))
                    .frame(height: 1)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)
                .allowsHitTesting(false)
            }
        }
    }
}

struct DashboardMainContent: View {
    let itemLists: [SDItemList]
    let getFormattedAmount: (SDItemList) -> String
    let getFormattedUnpaidAmount: (SDItemList) -> String?
    let itemListCounts: [UUID: Int]
    let categories: [UUID: (name: String, color: String, icon: String)]
    let itemListRowStatus: [UUID: ItemListRowStatus]
    let onItemTap: (SDItemList) -> Void
    let onTogglePaid: (SDItemList) -> Void
    let onRefresh: () async -> Void
    let onDelete: (SDItemList) async -> Void
    @Binding var showingFullMonth: Bool
    let hasItemsOutsideToday: Bool
    let getDayTotal: (Date) -> String
    let onOpenSettings: () -> Void
    let onAddForDate: (Date) -> Void
    @Binding var collapsedMonthDays: Set<Date>
    let bottomInset: AnyView

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, 4)
                .padding(.bottom, 2)

            ExpenseListView(
                itemLists: itemLists,
                getFormattedAmount: getFormattedAmount,
                getFormattedUnpaidAmount: getFormattedUnpaidAmount,
                itemListCounts: itemListCounts,
                categories: categories,
                itemListRowStatus: itemListRowStatus,
                onItemTap: onItemTap,
                onTogglePaid: onTogglePaid,
                onRefresh: onRefresh,
                onDelete: onDelete,
                getDayTotal: showingFullMonth ? getDayTotal : nil,
                focusedDate: nil,
                hideSectionHeaders: !showingFullMonth,
                onAddForDate: showingFullMonth ? onAddForDate : nil,
                collapsedDays: showingFullMonth ? $collapsedMonthDays : .constant([]),
                allowsDayCollapse: showingFullMonth
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.top, AppConstants.UserInterface.smallPadding)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            DashboardTopBarView(
                showingFullMonth: $showingFullMonth,
                hasItemsOutsideToday: hasItemsOutsideToday,
                onOpenSettings: onOpenSettings
            )
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomInset
        }
    }
}

struct DashboardDayPanel: View {
    let selectedCalendarDay: Date?
    let listDragOffset: CGFloat
    let content: AnyView
    let onDragChanged: (CGFloat) -> Void
    let onDismiss: () -> Void
    let onResetDrag: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity)

            if selectedCalendarDay != nil {
                ZStack(alignment: .bottom) {
                    content
                        .contentMargins(.top, 0, for: .scrollContent)

                    LinearGradient(
                        colors: [Color(.systemGray5).opacity(0), Color(.systemGray5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 10)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
        .offset(y: listDragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onDragChanged(max(0, value.translation.height))
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        onDismiss()
                    } else {
                        onResetDrag()
                    }
                }
        )
        .frame(maxHeight: .infinity)
    }
}
