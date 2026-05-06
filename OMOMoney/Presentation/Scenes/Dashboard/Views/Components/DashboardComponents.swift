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
    let monthLabel: String
    let monthTotal: String
    let todayTotal: String
    var overrideLabel: String? = nil
    var overrideTotal: String? = nil
    let onAddExpense: () -> Void

    private var displayLabel: String {
        if heroIsSuccess { return lastAddedDescription }
        if let overrideLabel { return LocalizationKey.Item.costOf.localized(with: overrideLabel) }
        return showingFullMonth ? monthLabel : LocalizationKey.Dashboard.costToday.localized
    }

    private var displayTotal: String {
        if let overrideTotal { return overrideTotal }
        return showingFullMonth ? monthTotal : todayTotal
    }

    var body: some View {
        TotalSpentCardView(
            label: displayLabel,
            totalAmount: displayTotal,
            onAddExpense: onAddExpense,
            isSuccess: heroIsSuccess
        )
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.padding)
        .padding(.bottom, 4)
        .animation(AnimationHelper.smoothSpring, value: showingFullMonth)
    }
}

struct DashboardBottomInset<Hero: View, Bar: View>: View {
    let heroSection: Hero
    let bottomBar: Bar

    init(
        @ViewBuilder heroSection: () -> Hero,
        @ViewBuilder bottomBar: () -> Bar
    ) {
        self.heroSection = heroSection()
        self.bottomBar = bottomBar()
    }

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            bottomBar
        }
        .background {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .bottom)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.02),
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

struct DashboardMainContent<EmptyState: View, BottomInset: View>: View {
    let allFormattedAmount: String
    let allFormattedUnpaidAmount: String?
    let categoryBoxes: [DashboardCategoryBoxData]
    let getFormattedAmount: (DashboardCategoryBoxData) -> String
    let getFormattedUnpaidAmount: (DashboardCategoryBoxData) -> String?
    let filteredItemLists: [SDItemList]
    let getItemListAmount: (SDItemList) -> String
    let getItemListUnpaidAmount: (SDItemList) -> String?
    let getDayTotal: (Date) -> String
    let getSearchSummary: (SDItemList) -> String?
    let getSearchMatchedSubtotal: (SDItemList) -> String?
    let getSearchMatchedUnpaid: (SDItemList) -> String?
    let customEmptyState: EmptyState
    let showCustomEmptyState: Bool
    let onRefresh: () async -> Void
    let onAllTap: () -> Void
    let onCategoryTap: (DashboardCategoryBoxData) -> Void
    let selectedFilterTitle: String?
    let selectedFilterIcon: String?
    let selectedFilterColorHex: String?
    @Binding var collapsedDays: Set<Date>
    let itemListRowStatus: [UUID: ItemListRowStatus]
    let onItemTap: (SDItemList) -> Void
    let onTogglePaid: (SDItemList) -> Void
    let onDelete: (SDItemList) async -> Void
    let onClearCategoryFilter: () -> Void
    @Binding var showingFullMonth: Bool
    let hasItemsOutsideToday: Bool
    let onOpenSettings: () -> Void
    let bottomInset: BottomInset

    init(
        allFormattedAmount: String,
        allFormattedUnpaidAmount: String?,
        categoryBoxes: [DashboardCategoryBoxData],
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        getFormattedUnpaidAmount: @escaping (DashboardCategoryBoxData) -> String?,
        filteredItemLists: [SDItemList],
        getItemListAmount: @escaping (SDItemList) -> String,
        getItemListUnpaidAmount: @escaping (SDItemList) -> String?,
        getDayTotal: @escaping (Date) -> String,
        getSearchSummary: @escaping (SDItemList) -> String?,
        getSearchMatchedSubtotal: @escaping (SDItemList) -> String?,
        getSearchMatchedUnpaid: @escaping (SDItemList) -> String?,
        @ViewBuilder customEmptyState: () -> EmptyState,
        showCustomEmptyState: Bool,
        onRefresh: @escaping () async -> Void,
        onAllTap: @escaping () -> Void,
        onCategoryTap: @escaping (DashboardCategoryBoxData) -> Void,
        selectedFilterTitle: String?,
        selectedFilterIcon: String?,
        selectedFilterColorHex: String?,
        collapsedDays: Binding<Set<Date>>,
        itemListRowStatus: [UUID: ItemListRowStatus],
        onItemTap: @escaping (SDItemList) -> Void,
        onTogglePaid: @escaping (SDItemList) -> Void,
        onDelete: @escaping (SDItemList) async -> Void,
        onClearCategoryFilter: @escaping () -> Void,
        showingFullMonth: Binding<Bool>,
        hasItemsOutsideToday: Bool,
        onOpenSettings: @escaping () -> Void,
        @ViewBuilder bottomInset: () -> BottomInset
    ) {
        self.allFormattedAmount = allFormattedAmount
        self.allFormattedUnpaidAmount = allFormattedUnpaidAmount
        self.categoryBoxes = categoryBoxes
        self.getFormattedAmount = getFormattedAmount
        self.getFormattedUnpaidAmount = getFormattedUnpaidAmount
        self.filteredItemLists = filteredItemLists
        self.getItemListAmount = getItemListAmount
        self.getItemListUnpaidAmount = getItemListUnpaidAmount
        self.getDayTotal = getDayTotal
        self.getSearchSummary = getSearchSummary
        self.getSearchMatchedSubtotal = getSearchMatchedSubtotal
        self.getSearchMatchedUnpaid = getSearchMatchedUnpaid
        self.customEmptyState = customEmptyState()
        self.showCustomEmptyState = showCustomEmptyState
        self.onRefresh = onRefresh
        self.onAllTap = onAllTap
        self.onCategoryTap = onCategoryTap
        self.selectedFilterTitle = selectedFilterTitle
        self.selectedFilterIcon = selectedFilterIcon
        self.selectedFilterColorHex = selectedFilterColorHex
        self._collapsedDays = collapsedDays
        self.itemListRowStatus = itemListRowStatus
        self.onItemTap = onItemTap
        self.onTogglePaid = onTogglePaid
        self.onDelete = onDelete
        self.onClearCategoryFilter = onClearCategoryFilter
        self._showingFullMonth = showingFullMonth
        self.hasItemsOutsideToday = hasItemsOutsideToday
        self.onOpenSettings = onOpenSettings
        self.bottomInset = bottomInset()
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, 4)
                .padding(.bottom, 2)

            Group {
                if let selectedFilterTitle {
                    ExpenseListView(
                        itemLists: filteredItemLists,
                        getFormattedAmount: getItemListAmount,
                        getFormattedUnpaidAmount: getItemListUnpaidAmount,
                        getSearchSummary: getSearchSummary,
                        getSearchMatchedSubtotal: getSearchMatchedSubtotal,
                        getSearchMatchedUnpaid: getSearchMatchedUnpaid,
                        itemListRowStatus: itemListRowStatus,
                        onItemTap: onItemTap,
                        onTogglePaid: onTogglePaid,
                        onRefresh: onRefresh,
                        onDelete: onDelete,
                        customEmptyState: { customEmptyState },
                        showCustomEmptyState: showCustomEmptyState,
                        getDayTotal: getDayTotal,
                        hideSectionHeaders: !showingFullMonth,
                        collapsedDays: $collapsedDays,
                        allowsDayCollapse: showingFullMonth
                    )
                    .safeAreaInset(edge: .top, spacing: 0) {
                        DashboardSelectedFilterBar(
                            title: selectedFilterTitle,
                            iconName: selectedFilterIcon,
                            colorHex: selectedFilterColorHex,
                            onClear: onClearCategoryFilter
                        )
                        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                        .padding(.bottom, 0)
                    }
                } else {
                    DashboardCategoryBoardView(
                        boxes: categoryBoxes,
                        allFormattedAmount: allFormattedAmount,
                        allFormattedUnpaidAmount: allFormattedUnpaidAmount,
                        getFormattedAmount: getFormattedAmount,
                        getFormattedUnpaidAmount: getFormattedUnpaidAmount,
                        onRefresh: onRefresh,
                        customEmptyState: { customEmptyState },
                        showCustomEmptyState: showCustomEmptyState,
                        onSelectAll: onAllTap,
                        onSelect: onCategoryTap
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .mask {
                ScrollEdgeFadeMask(
                    showsTopFade: selectedFilterTitle == nil || !showingFullMonth,
                    showsBottomFade: true
                )
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.top, selectedFilterTitle == nil ? AppConstants.UserInterface.smallPadding : 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

private struct DashboardSelectedFilterBar: View {
    let title: String
    let iconName: String?
    let colorHex: String?
    let onClear: () -> Void

    private var accentColor: Color {
        guard let colorHex else { return .accentColor }
        return Color(hex: colorHex) ?? .accentColor
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.12))
            .clipShape(Capsule())

            Spacer()

            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(width: 28, height: 28)
                .padding(.vertical, 6)
                .background(Color(.systemBackground))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ScrollEdgeFadeMask: View {
    let showsTopFade: Bool
    let showsBottomFade: Bool

    private let topFadeHeight: CGFloat = 12
    private let bottomFadeHeight: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            if showsTopFade {
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: topFadeHeight)
            } else {
                Color.black.frame(height: 0)
            }

            Color.black

            if showsBottomFade {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: bottomFadeHeight)
            } else {
                Color.black.frame(height: 0)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct DashboardDayPanel<Content: View>: View {
    let selectedCalendarDay: Date?
    let listDragOffset: CGFloat
    let content: Content
    let onDragChanged: (CGFloat) -> Void
    let onDismiss: () -> Void
    let onResetDrag: () -> Void

    init(
        selectedCalendarDay: Date?,
        listDragOffset: CGFloat,
        @ViewBuilder content: () -> Content,
        onDragChanged: @escaping (CGFloat) -> Void,
        onDismiss: @escaping () -> Void,
        onResetDrag: @escaping () -> Void
    ) {
        self.selectedCalendarDay = selectedCalendarDay
        self.listDragOffset = listDragOffset
        self.content = content()
        self.onDragChanged = onDragChanged
        self.onDismiss = onDismiss
        self.onResetDrag = onResetDrag
    }

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
