//
//  DashboardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

private enum DashboardActiveFilter {
    case all(DashboardCategoryRange)
    case category(DashboardCategoryBoxData)
}

enum DashboardViewMode {
    case calendar, list

    var title: String {
        switch self {
        case .calendar: return "Calendario"
        case .list:     return "Lista"
        }
    }
}

/// Wrapper view to navigate to ItemListDetailView with proper currency
struct ItemListDetailNavigationWrapper: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let highlightedSearchQuery: String?
    let onItemListUpdated: (SDItemList) -> Void
    let onPaidStatusChanged: (() -> Void)?

    var body: some View {
        ItemListDetailView(
            itemList: itemList,
            currencyCode: currencyCode,
            group: group,
            highlightedSearchQuery: highlightedSearchQuery,
            onItemListUpdated: onItemListUpdated,
            onPaidStatusChanged: onPaidStatusChanged
        )
    }
}

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var contentOpacity: Double = 0.0
    @State private var hasLoadedInitialData = false
    @State private var selectedCalendarDay: Date? = nil
    @State private var addItemListTrigger: AddItemListTrigger? = nil

    private struct AddItemListTrigger: Identifiable {
        let id = UUID()
        let initialDate: Date?
    }
    @State private var listDragOffset: CGFloat = 0
    @State private var displayedCalendarMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var viewMode: DashboardViewMode = .list
    @State private var collapsedMonthDays: Set<Date> = []
    @State private var showingFiltersSheet = false
    @State private var isSearchActive = false
    @State private var dismissSearchKeyboardToken = 0
    @State private var activeFilter: DashboardActiveFilter? = nil

    // Hero success flash
    @State private var heroIsSuccess: Bool = false
    @State private var lastAddedDescription: String = ""

    init() {
        // ✅ Clean Architecture: Use DI Container for all dependencies
        let container = AppDIContainer.shared

        self._viewModel = State(wrappedValue: DashboardViewModel(
            fetchItemListsUseCase: container.makeFetchItemListsUseCase(),
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            deleteItemListUseCase: container.makeDeleteItemListUseCase(),
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: container.makeFetchGroupsForUserUseCase(),
            fetchCategoriesUseCase: container.makeFetchCategoriesUseCase(),
            toggleAllItemsPaidInListUseCase: container.makeToggleAllItemsPaidInListUseCase(),
            toggleItemPaidUseCase: container.makeToggleItemPaidUseCase(),
            deleteGroupUseCase: container.makeDeleteGroupUseCase()
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        mainContentView
                    }
                }
                .opacity(viewModel.isLoading ? 1.0 : contentOpacity)

                if viewModel.isChangingGroup {
                    DashboardChangingGroupOverlay()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isChangingGroup)
                }
            }
            .background(Color(.systemBackground))
            .onChange(of: navigationPath) { _, path in
                if !path.isEmpty { viewModel.toast = nil }
            }
            .onChange(of: viewModel.isChangingGroup) { _, changing in
                if !changing {
                    selectedCalendarDay = nil
                    activeFilter = nil
                    listDragOffset = 0
                    displayedCalendarMonth = Calendar.current.startOfMonth(for: Date())
                    viewMode = .list
                    viewModel.showingFullMonth = false
                    isSearchActive = false
                    viewModel.clearSearch()
                }
            }
            .navigationDestination(for: SDItemList.self) { itemList in
                if let group = viewModel.currentGroup {
                    ItemListDetailNavigationWrapper(
                        itemList: itemList,
                        currencyCode: group.currency,
                        group: group,
                        highlightedSearchQuery: viewModel.hasActiveSearch ? viewModel.searchQuery : nil,
                        onItemListUpdated: { updated in
                            Task { await viewModel.updateItemList(updated) }
                        },
                        onPaidStatusChanged: {
                            Task { await viewModel.refreshTotals() }
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                Task { await viewModel.refreshCategories() }
            } content: {
                if let user = viewModel.currentUser {
                    SettingsSheetView(
                        user: user,
                        onUserUpdated: { updated in
                            viewModel.updateCurrentUser(updated)
                        }
                    )
                }
            }
            .sheet(item: $addItemListTrigger) { trigger in
                if let group = viewModel.currentGroup {
                    NavigationStack {
                        AddItemListView(
                            group: group,
                            initialDate: trigger.initialDate,
                            onItemListCreated: { createdItemList in
                                guard !heroIsSuccess else {
                                    addItemListTrigger = nil
                                    Task { await viewModel.addItemList(createdItemList) }
                                    return
                                }
                                lastAddedDescription = createdItemList.itemListDescription
                                withAnimation(AnimationHelper.smoothSpring) {
                                    heroIsSuccess = true
                                }
                                addItemListTrigger = nil
                                Task {
                                    await viewModel.addItemList(createdItemList)
                                    try? await Task.sleep(for: .milliseconds(900))
                                    withAnimation(AnimationHelper.smoothSpring) {
                                        heroIsSuccess = false
                                    }
                                }
                            },
                            onCancel: {
                                addItemListTrigger = nil
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showingFiltersSheet) {
                NavigationStack {
                    DashboardMonthFilterSheet(
                        selectedMonth: viewModel.selectedMonthAnchor,
                        availableYears: viewModel.availableFilterYears,
                        isCustomFilterActive: viewModel.isCustomMonthFilterActive,
                        onApply: { month in
                            viewModel.applyMonthFilter(month)
                            showingFiltersSheet = false
                        },
                        onReset: {
                            viewModel.resetMonthFilterToCurrentMonth()
                            showingFiltersSheet = false
                        },
                        onClose: { showingFiltersSheet = false }
                    )
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .toast($viewModel.toast)
        .onAppear {
            // Only load data on first appearance to avoid splash on navigation back
            guard !hasLoadedInitialData else {
                print("📍 DashboardView: Navigated back, refreshing data...")
                // 🔄 Refresh data to get updated totals
                Task {
                    await viewModel.refreshData()
                }
                return
            }

            hasLoadedInitialData = true
            Task {
                await viewModel.loadDashboardData()
                // Fade in suave del contenido después de cargar - SOLO UNA VEZ
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seg para asegurar render
                withAnimation(.easeIn(duration: 0.5)) {
                    contentOpacity = 1.0
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    private var loadingView: some View {
        DashboardLoadingState()
    }
    
    private func errorView(_ message: String) -> some View {
        DashboardErrorState(message: message) {
            Task { await viewModel.loadDashboardData() }
        }
    }
    
    private var mainContentView: some View {
        DashboardMainContent(
            allFormattedAmount: viewModel.formattedVisibleRangePaidTotal(showingFullMonth: viewModel.showingFullMonth),
            allFormattedUnpaidAmount: viewModel.formattedVisibleRangeUnpaidTotal(showingFullMonth: viewModel.showingFullMonth),
            categoryBoxes: viewModel.visibleCategoryBoxes,
            getFormattedAmount: { viewModel.formattedAmount(for: $0) },
            getFormattedUnpaidAmount: { viewModel.formattedUnpaidAmount(for: $0) },
            filteredItemLists: activeFilteredItemLists,
            getItemListAmount: { viewModel.formattedPaid(for: $0) },
            getItemListUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
            getSearchSummary: { viewModel.formattedSearchSummary(for: $0) },
            getSearchMatchedSubtotal: { viewModel.formattedSearchMatchedSubtotal(for: $0) },
            getSearchMatchedUnpaid: { viewModel.formattedSearchMatchedUnpaid(for: $0) },
            customEmptyState: viewModel.hasActiveSearch || viewModel.isCustomMonthFilterActive
                ? AnyView(DashboardNoResultsState())
                : nil,
            onRefresh: { await viewModel.refreshData() },
            onAllTap: {
                withAnimation(AnimationHelper.smoothSpring) {
                    activeFilter = .all(viewModel.showingFullMonth ? .month : .today)
                }
            },
            onCategoryTap: { box in
                withAnimation(AnimationHelper.smoothSpring) {
                    activeFilter = .category(box)
                }
            },
            selectedFilterTitle: activeFilterTitle,
            selectedFilterIcon: activeFilterIcon,
            selectedFilterColorHex: activeFilterColorHex,
            itemListRowStatus: viewModel.itemListRowStatus,
            onItemTap: { itemList in
                if isSearchActive {
                    dismissSearchKeyboardToken += 1
                }
                navigationPath.append(itemList)
            },
            onTogglePaid: { viewModel.togglePaid(for: $0) },
            onDelete: { await viewModel.deleteItemList($0) },
            onClearCategoryFilter: {
                withAnimation(AnimationHelper.smoothSpring) {
                    activeFilter = nil
                }
            },
            showingFullMonth: $viewModel.showingFullMonth,
            hasItemsOutsideToday: viewModel.hasItemsOutsideToday,
            onOpenSettings: { viewModel.openSettings() },
            bottomInset: AnyView(bottomInset)
        )
        .animation(AnimationHelper.smoothSpring, value: selectedCalendarDay == nil)
        .animation(AnimationHelper.quickEase, value: viewMode == .calendar)
        .onChange(of: viewModel.currentGroup?.id) { _, _ in
            collapsedMonthDays.removeAll()
        }
        .onChange(of: viewModel.showingFullMonth) { _, isShowingMonth in
            let targetRange: DashboardCategoryRange = isShowingMonth ? .month : .today
            withAnimation(AnimationHelper.quickEase) {
                switch activeFilter {
                case .all:
                    activeFilter = .all(targetRange)
                case .category(let selectedCategoryBox):
                    activeFilter = viewModel.categoryBox(
                        forCategoryId: selectedCategoryBox.categoryId,
                        in: targetRange
                    ).map { .category($0) }
                case nil:
                    break
                }
            }
        }
        .onChange(of: viewModel.itemListTotals) { _, _ in
            refreshActiveFilter()
        }
    }

    private func refreshActiveFilter() {
        switch activeFilter {
        case .all:
            break
        case .category(let box):
            activeFilter = viewModel.categoryBox(forCategoryId: box.categoryId, in: box.range).map { .category($0) }
        case nil:
            break
        }
    }

    private var activeFilteredItemLists: [SDItemList] {
        switch activeFilter {
        case .all(let range):
            return range == .month ? viewModel.filteredMonthItemLists : viewModel.filteredTodayItemLists
        case .category(let selectedCategoryBox):
            return viewModel.filteredItemLists(
                forCategoryId: selectedCategoryBox.categoryId,
                in: selectedCategoryBox.range
            )
        case nil:
            return []
        }
    }

    private var activeFilterTitle: String? {
        switch activeFilter {
        case .all:
            return LocalizationKey.General.all.localized
        case .category(let box):
            return box.categoryName
        case nil:
            return nil
        }
    }

    private var activeFilterIcon: String? {
        switch activeFilter {
        case .all:
            return "square.grid.2x2.fill"
        case .category(let box):
            return box.categoryIcon
        case nil:
            return nil
        }
    }

    private var activeFilterColorHex: String? {
        switch activeFilter {
        case .all:
            return nil
        case .category(let box):
            return box.categoryColorHex
        case nil:
            return nil
        }
    }

    private var bottomInset: some View {
        DashboardBottomInset(
            heroSection: AnyView(
                Group {
                    if !isSearchActive {
                        DashboardHeroSection(
                            heroIsSuccess: heroIsSuccess,
                            lastAddedDescription: lastAddedDescription,
                            showingFullMonth: viewModel.showingFullMonth,
                            monthLabel: viewModel.monthHeroLabel,
                            monthTotal: viewModel.formattedCachedMonthTotal(),
                            todayTotal: viewModel.formattedTodayTotal,
                            overrideLabel: activeCategoryBox?.categoryName,
                            overrideTotal: activeCategoryBox.map { viewModel.formattedCurrency($0.totalAmount) },
                            onAddExpense: { addItemListTrigger = AddItemListTrigger(initialDate: selectedCalendarDay) }
                        )
                    }
                }
            ),
            bottomBar: AnyView(
                DashboardBottomBarView(
                    searchText: $viewModel.searchQuery,
                    isSearchActive: $isSearchActive,
                    dismissKeyboardToken: dismissSearchKeyboardToken,
                    currentGroup: viewModel.currentGroup,
                    availableGroups: viewModel.availableGroups,
                    userId: viewModel.currentUser?.id,
                    isChangingGroup: viewModel.isChangingGroup,
                    isFilterActive: viewModel.isCustomMonthFilterActive,
                    onGroupChange: { newGroup in Task { await viewModel.changeGroup(to: newGroup) } },
                    onGroupCreated: { newGroup in viewModel.addGroup(newGroup) },
                    onDeleteGroup: { deletedGroup in try await viewModel.deleteGroup(deletedGroup) },
                    onOpenFilters: { showingFiltersSheet = true }
                )
            )
        )
    }

    private var activeCategoryBox: DashboardCategoryBoxData? {
        guard case .category(let box) = activeFilter else { return nil }
        return box
    }

    // View picker: filter pill on left, settings icon on right

    private var dayListPanel: some View {
        DashboardDayPanel(
            selectedCalendarDay: selectedCalendarDay,
            listDragOffset: listDragOffset,
            content: AnyView(
                Group {
                    if let day = selectedCalendarDay {
                        dayExpenseList(for: day, isCompact: true)
                    }
                }
            ),
            onDragChanged: { listDragOffset = $0 },
            onDismiss: {
                withAnimation(AnimationHelper.smoothSpring) {
                    selectedCalendarDay = nil
                }
                listDragOffset = 0
            },
            onResetDrag: {
                withAnimation(AnimationHelper.smoothSpring) {
                    listDragOffset = 0
                }
            }
        )
    }

    private func dayExpenseList(for date: Date, onItemTap: ((SDItemList) -> Void)? = nil, isCompact: Bool = false) -> some View {
        let cal = Calendar.current
        let source = viewModel.itemLists.filter {
            cal.isDate($0.date, inSameDayAs: date)
        }
        return ExpenseListView(
            itemLists: viewModel.filteredSearchResults(from: source),
            getFormattedAmount: { viewModel.formattedPaid(for: $0) },
            getFormattedUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
            getSearchSummary: { viewModel.formattedSearchSummary(for: $0) },
            getSearchMatchedSubtotal: { viewModel.formattedSearchMatchedSubtotal(for: $0) },
            getSearchMatchedUnpaid: { viewModel.formattedSearchMatchedUnpaid(for: $0) },
            itemListRowStatus: viewModel.itemListRowStatus,
            onItemTap: { item in
                if let customTap = onItemTap {
                    customTap(item)
                } else {
                    if isSearchActive {
                        dismissSearchKeyboardToken += 1
                    }
                    navigationPath.append(item)
                }
            },
            onTogglePaid: { viewModel.togglePaid(for: $0) },
            onRefresh: { await viewModel.refreshData() },
            onDelete: { await viewModel.deleteItemList($0) },
            isCompact: isCompact
        )
        .frame(maxHeight: .infinity)
    }

    // MARK: - Debug Helper
    
    /// Debug function to log all entities in the database (moved from AppContentView)
    @MainActor
    private func logAllEntities() async {
        print("\n🔍 =========================")
        print("🔍 DEBUG: Logging all entities")
        print("🔍 =========================")
        
        if let currentUser = viewModel.currentUser {
                print("\n👤 USUARIO:")
                print("   ID: \(currentUser.id.uuidString)")  // ✅ id is NOT optional
                print("   Nombre: \(currentUser.name)")
                print("   Email: \(currentUser.email)")
                print("   Creado: \(currentUser.createdAt)")

                if let currentGroup = viewModel.currentGroup {
                    print("\n🏢 GRUPO ACTUAL:")
                    print("   ID: \(currentGroup.id.uuidString)")  // ✅ id is NOT optional
                    print("   Nombre: \(currentGroup.name)")
                    print("   Moneda: \(currentGroup.currency)")
                    print("   Creado: \(currentGroup.createdAt)")
                }
                
                print("\n📋 ITEM LISTS (\(viewModel.itemLists.count)):")
                for (index, itemList) in viewModel.itemLists.enumerated() {
                    print("   \(index + 1). ID: \(itemList.id.uuidString)")
                    print("      Descripción: \(itemList.itemListDescription)")
                    print("      Fecha: \(itemList.date)")
                    // TODO: getFormattedItemListTotal is async - need to calculate totals separately
                    print("      Total: (async calculation needed)")
                }
                
                print("\n💰 TOTAL GASTADO: \(viewModel.formattedTotalSpent)")
                
        } else {
            print("\n❌ No se encontró usuario actual")
        }
        
        print("🔍 =========================\n")
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
