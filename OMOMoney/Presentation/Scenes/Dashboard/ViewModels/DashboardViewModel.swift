import Foundation
import SwiftUI

enum ItemListPaidStatus {
    case none       // 0 items, or all unpaid
    case partial    // some paid, some not
    case all        // all items paid
}

enum ItemListRowStatus {
    case neutral
    case unpaid
    case partial
    case paid
}

enum DashboardCategoryRange: String, Hashable {
    case today
    case month

    var title: String {
        switch self {
        case .today:
            LocalizationKey.Dashboard.today.localized
        case .month:
            LocalizationKey.Dashboard.thisMonth.localized
        }
    }
}

enum DashboardCategoryBoxSize: Hashable {
    case small
    case medium
    case large
}

struct DashboardCategoryBoxData: Identifiable, Hashable {
    let categoryId: UUID
    let categoryName: String
    let categoryColorHex: String
    let categoryIcon: String
    let paidAmount: Double
    let unpaidAmount: Double
    let totalAmount: Double
    let itemListCount: Int
    let itemCount: Int
    let sizeTier: DashboardCategoryBoxSize
    let range: DashboardCategoryRange

    var id: String {
        "\(range.rawValue)-\(categoryId.uuidString)"
    }
}


@MainActor

@Observable
class DashboardViewModel {
    private typealias ItemListData = (id: UUID, paidTotal: Double, unpaidTotal: Double, count: Int, paidStatus: ItemListPaidStatus, rowStatus: ItemListRowStatus)
    private typealias CategoryMetadata = (name: String, color: String, icon: String)

    private struct CachedItemListData {
        let paidTotal: Double
        let unpaidTotal: Double
        let count: Int
        let paidStatus: ItemListPaidStatus
        let rowStatus: ItemListRowStatus
    }

    private struct CategoryAggregate {
        let categoryId: UUID
        let categoryName: String
        let categoryColorHex: String
        let categoryIcon: String
        var paidAmount: Double
        var unpaidAmount: Double
        var itemListCount: Int
        var itemCount: Int
    }

    struct ItemListSearchSummary {
        let listMatched: Bool
        let matchedItemCount: Int
        let matchedSubtotal: Double
        let matchedUnpaidSubtotal: Double

        var hasItemMatches: Bool {
            matchedItemCount > 0
        }
    }

    // MARK: - Published Properties
    var itemLists: [SDItemList] = [] {
        didSet {
            updateCurrentMonthCache()
        }
    }
    var currentMonthItemLists: [SDItemList] = []
    var totalSpent: Double = 0.0
    var todayTotal: Double = 0.0
    var todayUnpaidTotal: Double = 0.0
    var currentMonthTotal: Double = 0.0
    var currentMonthUnpaidTotal: Double = 0.0
    var itemListTotals: [UUID: Double] = [:]
    var itemListUnpaidTotals: [UUID: Double] = [:]
    var itemListCounts: [UUID: Int] = [:]
    var itemListPaidStatus: [UUID: ItemListPaidStatus] = [:]
    var itemListRowStatus: [UUID: ItemListRowStatus] = [:]
    var categories: [UUID: (name: String, color: String, icon: String)] = [:]
    var isLoading = false
    var isRefreshing = false
    var isChangingGroup = false
    var isDeletingGroup = false
    var errorMessage: String?
    var toast: ToastMessage?
    var currentGroup: SDGroup?
    var currentUser: SDUser?
    var availableGroups: [SDGroup] = []
    var showingSettings = false
    var showingFullMonth = false
    var selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
    var searchQuery = ""

    // MARK: - Filtered Lists

    var todayItemLists: [SDItemList] {
        itemLists.filter { Calendar.current.isDateInToday($0.date) }
    }

    var monthItemLists: [SDItemList] {
        itemLists.filter { Calendar.current.isDate($0.date, equalTo: selectedMonthAnchor, toGranularity: .month) }
    }

    var filteredTodayItemLists: [SDItemList] {
        filteredItemLists(from: todayItemLists)
    }

    var filteredMonthItemLists: [SDItemList] {
        filteredItemLists(from: monthItemLists)
    }

    var todayCategoryBoxes: [DashboardCategoryBoxData] {
        makeCategoryBoxes(from: filteredTodayItemLists, range: .today)
    }

    var monthCategoryBoxes: [DashboardCategoryBoxData] {
        makeCategoryBoxes(from: filteredMonthItemLists, range: .month)
    }

    var visibleCategoryBoxes: [DashboardCategoryBoxData] {
        showingFullMonth ? monthCategoryBoxes : todayCategoryBoxes
    }

    func filteredSearchResults(from source: [SDItemList]) -> [SDItemList] {
        filteredItemLists(from: source)
    }

    var hasItemsOutsideToday: Bool {
        monthItemLists.count > todayItemLists.count || isCustomMonthFilterActive
    }

    var todayRawTotal: Double {
        todayTotal
    }

    var isCustomMonthFilterActive: Bool {
        !Calendar.current.isDate(selectedMonthAnchor, equalTo: Date(), toGranularity: .month)
    }

    var hasActiveSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var selectedMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedMonthAnchor).capitalized(with: Locale.current)
    }

    var monthHeroLabel: String {
        isCustomMonthFilterActive ? selectedMonthTitle : LocalizationKey.Dashboard.costThisMonth.localized
    }

    var availableFilterYears: [Int] {
        let years = Set(itemLists.map { Calendar.current.component(.year, from: $0.date) })
            .union([Calendar.current.component(.year, from: Date())])
        return years.sorted(by: >)
    }


    // MARK: - Use Cases
    private let fetchItemListsUseCase: FetchItemListsUseCase
    private let fetchItemsUseCase: FetchItemsUseCase
    private let deleteItemListUseCase: DeleteItemListUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let toggleAllItemsPaidInListUseCase: ToggleAllItemsPaidInListUseCase
    private let toggleItemPaidUseCase: ToggleItemPaidUseCase
    private let deleteGroupUseCase: DeleteGroupUseCase

    // MARK: - Cache
    private let cacheManager = CacheManager.shared
    private var paidToggleTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Initialization
    init(
        fetchItemListsUseCase: FetchItemListsUseCase,
        fetchItemsUseCase: FetchItemsUseCase,
        deleteItemListUseCase: DeleteItemListUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        toggleAllItemsPaidInListUseCase: ToggleAllItemsPaidInListUseCase,
        toggleItemPaidUseCase: ToggleItemPaidUseCase,
        deleteGroupUseCase: DeleteGroupUseCase
    ) {
        self.fetchItemListsUseCase = fetchItemListsUseCase
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteItemListUseCase = deleteItemListUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.toggleAllItemsPaidInListUseCase = toggleAllItemsPaidInListUseCase
        self.toggleItemPaidUseCase = toggleItemPaidUseCase
        self.deleteGroupUseCase = deleteGroupUseCase
    }
    
    // MARK: - Public Methods
    
    func loadDashboardData() async {
        print("🔄 DashboardViewModel: loadDashboardData() starting...")
        
        print("🔄 DashboardViewModel: Setting isLoading = true")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 DashboardViewModel: Getting current user...")
            guard let user = try await getCurrentUserUseCase.execute() else {
                print("❌ DashboardViewModel: No user found")
                errorMessage = "No user found. Please create a user first."
                isLoading = false
                return
            }
            print("✅ DashboardViewModel: Found user: \(user.name)")

            print("🔄 DashboardViewModel: Getting user groups...")
            let groups = try await fetchGroupsForUserUseCase.execute(userId: user.id)
            guard let firstGroup = groups.first else {
                print("❌ DashboardViewModel: No groups found")
                errorMessage = "No groups found. Please create a group first."
                isLoading = false
                return
            }
            print("✅ DashboardViewModel: Found \(groups.count) group(s), using: \(firstGroup.name)")

            print("🔄 DashboardViewModel: Getting ItemLists for group...")
            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: firstGroup.id)
            print("✅ DashboardViewModel: Found \(fetchedItemLists.count) ItemLists")

            print("🔄 DashboardViewModel: Loading categories...")
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: firstGroup.id)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories")

            print("🔄 DashboardViewModel: Updating UI with new data...")
            currentUser = user
            currentGroup = firstGroup
            availableGroups = groups
            selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
            itemLists = fetchedItemLists
            categories = categoriesDict

            await calculateTotalSpent()

            isLoading = false
            
        } catch {
            errorMessage = "Error loading dashboard data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func refreshData() async {
        print("🔄 DashboardViewModel: refreshData() - SMOOTH NATIVE REFRESH")
        
        isRefreshing = true
        
        do {
            guard let group = currentGroup else {
                print("⚠️ DashboardViewModel: No current group, skipping refresh")
                isRefreshing = false
                return
            }
            
            let groupId = group.id
            let currentItemLists = itemLists

            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)
            
            print("🔍 DashboardViewModel: Current count: \(currentItemLists.count), Fetched count: \(fetchedItemLists.count)")
            
            let cal = Calendar.current
            let sortedItemLists = fetchedItemLists.sorted {
                let d0 = cal.startOfDay(for: $0.date)
                let d1 = cal.startOfDay(for: $1.date)
                return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                itemLists = sortedItemLists
            }

            await calculateTotalSpent()

            print("✅ DashboardViewModel: UI updated with \(sortedItemLists.count) items, totals recalculated")
            isRefreshing = false
            print("✅ DashboardViewModel: Refresh completed smoothly")
            
        } catch {
            print("❌ DashboardViewModel: Error during refresh: \(error.localizedDescription)")
            isRefreshing = false
        }
    }

    func addExpense() {
        print("Add expense tapped - navigating to AddItemListView")
    }
    
    // MARK: - Group Management
    
    func changeGroup(to newGroup: SDGroup) async {
        guard newGroup.id != currentGroup?.id else {
            print("⚠️ DashboardViewModel: Grupo ya seleccionado, ignorando cambio")
            return
        }

        print("🔄 DashboardViewModel: Cambiando a grupo: \(newGroup.name)")

        isChangingGroup = true

        do {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let groupId = newGroup.id
            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)

            print("🔄 DashboardViewModel: Loading categories for new group...")
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories for new group")

            currentGroup = newGroup
            selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
            itemListTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListUnpaidTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListCounts = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0) })
            itemListPaidStatus = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, ItemListPaidStatus.none) })
            itemListRowStatus = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, ItemListRowStatus.neutral) })
            itemLists = fetchedItemLists
            categories = categoriesDict

            await calculateTotalSpent()

            isChangingGroup = false
            print("✅ DashboardViewModel: Grupo cambiado exitosamente")
            print("📋 DashboardViewModel: Cargados \(fetchedItemLists.count) ItemLists")
        } catch {
            isChangingGroup = false
            print("❌ DashboardViewModel: Error cambiando grupo: \(error)")
        }
    }
    
    func refreshAvailableGroups() async {
        guard let user = currentUser else {
            print("⚠️ DashboardViewModel: No hay usuario actual, no se pueden recargar grupos")
            return
        }
        
        print("🔄 DashboardViewModel: Recargando grupos disponibles...")

        do {
            let userId = user.id
            let groups = try await fetchGroupsForUserUseCase.execute(userId: userId)

            availableGroups = groups
            print("✅ DashboardViewModel: Grupos recargados. Total: \(groups.count)")
        } catch {
            print("❌ DashboardViewModel: Error recargando grupos: \(error)")
        }
    }
    
    func addGroup(_ newGroup: SDGroup) {
        print("➕ [DashboardVM] addGroup() llamado")
        print("➕ [DashboardVM] Grupo nuevo: '\(newGroup.name)' (ID: \(newGroup.id.uuidString))")
        print("➕ [DashboardVM] availableGroups.count ANTES: \(availableGroups.count)")

        guard !availableGroups.contains(where: { $0.id == newGroup.id }) else {
            print("⚠️ [DashboardVM] Grupo ya existe en lista - SKIP")
            return
        }

        availableGroups.append(newGroup)
        print("✅ [DashboardVM] addGroup() completado")
    }
    
    func removeGroup(_ group: SDGroup) {
        availableGroups.removeAll { $0.id == group.id }
    }

    func deleteGroup(_ group: SDGroup) async throws {
        withAnimation { availableGroups.removeAll { $0.id == group.id } }
        do {
            try await deleteGroupUseCase.execute(groupId: group.id)
        } catch {
            availableGroups.append(group)
            availableGroups.sort { $0.name < $1.name }
            throw error
        }
    }
    
    func openSettings() {
        showingSettings = true
    }

    func updateCurrentUser(_ user: SDUser) {
        currentUser = user
    }

    func refreshCategories() async {
        guard let groupId = currentGroup?.id else { return }
        do {
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var dict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories { dict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon) }
            categories = dict
        } catch {}
    }

    func addItemList(_ itemList: SDItemList) async {
        let itemListDesc = itemList.itemListDescription
        print("\n🟢 ============================================")
        print("📋 [ADD] Adding ItemList: '\(itemListDesc)'")
        print("🟢 ============================================")

        guard let currentGroupId = currentGroup?.id else {
            print("⚠️ [ADD] No current group selected - skipping")
            return
        }

        if itemList.group?.id != currentGroupId {
            print("⚠️ [ADD] ItemList belongs to different group")
            return
        }

        if itemLists.contains(where: { $0.id == itemList.id }) {
            print("⚠️ [ADD] ItemList already exists in dashboard")
            return
        }

        let cal = Calendar.current
        let sortedItemLists = (itemLists + [itemList]).sorted {
            let d0 = cal.startOfDay(for: $0.date)
            let d1 = cal.startOfDay(for: $1.date)
            return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
        }

        itemListTotals[itemList.id] = 0.0
        itemListUnpaidTotals[itemList.id] = 0.0
        itemListCounts[itemList.id] = 0
        itemListPaidStatus[itemList.id] = .none
        itemListRowStatus[itemList.id] = .neutral

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            itemLists = sortedItemLists
        }
        await calculateTotalSpent()

        print("✅ [ADD] ItemList added successfully to UI")
    }

    @MainActor
    func clearCache() async {
        cacheManager.clearAllCaches()
        print("🗂️ DashboardViewModel: All caches cleared")
    }
    
    func togglePaid(for itemList: SDItemList) {
        let itemCount = itemListCounts[itemList.id] ?? 0

        guard itemCount > 0 else {
            toast = ToastMessage(LocalizationKey.Dashboard.emptyEntryToast.localized, type: .info)
            return
        }

        let previousStates = itemList.items.map { (id: $0.id, isPaid: $0.isPaid) }
        let currentStatus = itemListPaidStatus[itemList.id] ?? .none
        let newValue = currentStatus == .all ? false : true
        itemList.lastModifiedAt = Date()
        itemListPaidStatus[itemList.id] = newValue ? .all : .none
        itemList.items.forEach { $0.isPaid = newValue }
        itemListRowStatus[itemList.id] = makeRowStatus(
            totalAmount: itemList.totalAmount,
            itemCount: itemCount,
            paidStatus: itemListPaidStatus[itemList.id] ?? .none
        )

        if itemCount > 1 {
            toast = ToastMessage(
                newValue
                    ? LocalizationKey.Dashboard.markedAllPaid.localized
                    : LocalizationKey.Dashboard.markedAllPending.localized,
                type: .info,
                actionTitle: LocalizationKey.Dashboard.undo.localized
            ) { [weak self] in
                Task { @MainActor in
                    await self?.undoTogglePaid(for: itemList, previousStates: previousStates)
                }
            }
        } else {
            toast = nil
        }

        paidToggleTasks[itemList.id] = Task {
            try? await toggleAllItemsPaidInListUseCase.execute(itemListId: itemList.id, isPaid: newValue)
            await calculateTotalSpent()
            paidToggleTasks[itemList.id] = nil
        }
    }

    private func undoTogglePaid(
        for itemList: SDItemList,
        previousStates: [(id: UUID, isPaid: Bool)]
    ) async {
        if let pendingTask = paidToggleTasks[itemList.id] {
            await pendingTask.value
        }

        for state in previousStates {
            itemList.items.first { $0.id == state.id }?.isPaid = state.isPaid
            try? await toggleItemPaidUseCase.execute(itemId: state.id, isPaid: state.isPaid)
        }
        itemList.lastModifiedAt = Date()
        await calculateTotalSpent()
        toast = ToastMessage(LocalizationKey.Dashboard.changeUndone.localized, type: .info)
    }

    func forceRefresh() async {
        await clearCache()
        await loadDashboardData()
        print("🔄 DashboardViewModel: Force refresh completed")
    }
    
    // MARK: - Private Methods

    func refreshTotals() async {
        await calculateTotalSpent()
    }

    func applyMonthFilter(_ month: Date) {
        selectedMonthAnchor = Calendar.current.startOfMonth(for: month)
        updateCurrentMonthCache()
        refreshSelectedMonthTotal()
        withAnimation(AnimationHelper.quickSpring) {
            showingFullMonth = true
        }
    }

    func resetMonthFilterToCurrentMonth() {
        selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
        updateCurrentMonthCache()
        refreshSelectedMonthTotal()
    }

    func clearSearch() {
        searchQuery = ""
    }

    private func calculateTotalSpent() async {
        let results = await withTaskGroup(of: ItemListData.self) { group in
            var items: [ItemListData] = []

            for itemList in itemLists {
                group.addTask {
                    return await self.getItemListData(itemList)
                }
            }

            for await result in group {
                items.append(result)
            }

            return items
        }

        let totals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidTotal) })
        let unpaidTotals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.unpaidTotal) })
        let counts = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.count) })
        let paidStatuses = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidStatus) })
        let rowStatuses = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.rowStatus) })

        itemListTotals = totals
        itemListUnpaidTotals = unpaidTotals
        itemListCounts = counts
        itemListPaidStatus = paidStatuses
        itemListRowStatus = rowStatuses
        todayTotal = todayItemLists.reduce(0.0) { $0 + (totals[$1.id] ?? 0) }
        todayUnpaidTotal = todayItemLists.reduce(0.0) { $0 + (unpaidTotals[$1.id] ?? 0) }
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { $0 + (totals[$1.id] ?? 0) }
        currentMonthUnpaidTotal = currentMonthItemLists.reduce(0.0) { $0 + (unpaidTotals[$1.id] ?? 0) }

        let newTotal = totals.values.reduce(0.0) { total, itemListTotal in
            guard itemListTotal.isFinite else { return total }
            return total + itemListTotal
        }

        if newTotal.isFinite {
            totalSpent = max(0, newTotal)
        } else {
            totalSpent = 0.0
        }
    }
    
    // MARK: - Helper Methods

    private func makeCurrencyFormatter() -> NumberFormatter {
        let code = currentGroup?.currency ?? "EUR"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = code
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        return formatter
    }

    func formattedPaid(for itemList: SDItemList) -> String {
        guard let total = itemListTotals[itemList.id] else { return "€0.00" }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "€0.00"
    }

    func formattedUnpaid(for itemList: SDItemList) -> String? {
        guard let status = itemListPaidStatus[itemList.id],
              status != .all,
              let unpaid = itemListUnpaidTotals[itemList.id],
              unpaid > 0 else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: unpaid))
    }

    func formattedSearchSummary(for itemList: SDItemList) -> String? {
        guard let summary = searchSummary(for: itemList), summary.hasItemMatches else { return nil }

        let key = summary.matchedItemCount == 1
            ? LocalizationKey.Dashboard.searchItemSummarySingle
            : LocalizationKey.Dashboard.searchItemSummaryMultiple

        return key.localized(with: summary.matchedItemCount)
    }

    func formattedSearchMatchedSubtotal(for itemList: SDItemList) -> String? {
        guard let summary = searchSummary(for: itemList), summary.hasItemMatches else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: summary.matchedSubtotal)) ?? "€0.00"
    }

    func formattedSearchMatchedUnpaid(for itemList: SDItemList) -> String? {
        guard let summary = searchSummary(for: itemList), summary.hasItemMatches else { return nil }
        guard summary.matchedUnpaidSubtotal > 0.000_001 else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: summary.matchedUnpaidSubtotal))
    }

    func formattedTotal(for date: Date) -> String {
        let cal = Calendar.current
        let dayTotal = itemLists
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        return makeCurrencyFormatter().string(from: NSNumber(value: dayTotal)) ?? "€0.00"
    }

    func formattedCurrency(_ amount: Double) -> String {
        makeCurrencyFormatter().string(from: NSNumber(value: amount)) ?? "€0.00"
    }

    func formattedAmount(for box: DashboardCategoryBoxData) -> String {
        formattedCurrency(box.paidAmount)
    }

    func formattedUnpaidAmount(for box: DashboardCategoryBoxData) -> String? {
        guard box.unpaidAmount > 0.000_001 else { return nil }
        return formattedCurrency(box.unpaidAmount)
    }

    var formattedTodayTotal: String {
        makeCurrencyFormatter().string(from: NSNumber(value: todayTotal)) ?? "€0.00"
    }

    func formattedCachedMonthTotal() -> String {
        makeCurrencyFormatter().string(from: NSNumber(value: currentMonthTotal)) ?? "€0.00"
    }

    func formattedVisibleRangePaidTotal(showingFullMonth: Bool) -> String {
        formattedCurrency(showingFullMonth ? currentMonthTotal : todayTotal)
    }

    func formattedVisibleRangeUnpaidTotal(showingFullMonth: Bool) -> String? {
        let amount = showingFullMonth ? currentMonthUnpaidTotal : todayUnpaidTotal
        guard amount > 0.000_001 else { return nil }
        return formattedCurrency(amount)
    }

    func formattedTotal(forMonth date: Date) -> String {
        let cal = Calendar.current
        let monthTotal = itemLists
            .filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        return makeCurrencyFormatter().string(from: NSNumber(value: monthTotal)) ?? "€0.00"
    }

    var formattedTotalSpent: String {
        guard totalSpent.isFinite else {
            print("❌ DashboardViewModel: formattedTotalSpent called with NaN/Infinite value!")
            return "€0.00"
        }
        let formatter = makeCurrencyFormatter()
        return formatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
    }
    
    var recentItemLists: [SDItemList] {
        return Array(itemLists.prefix(10))
    }
    
    private func updateCurrentMonthCache() {
        let calendar = Calendar.current

        let filtered = itemLists.filter { itemList in
            calendar.isDate(itemList.date, equalTo: selectedMonthAnchor, toGranularity: .month)
        }

        let currentIds = Set(currentMonthItemLists.map { $0.id })
        let filteredIds = Set(filtered.map { $0.id })

        if currentIds != filteredIds {
            print("🗓️ DashboardViewModel: Updating current month cache")
            print("   - Total ItemLists: \(itemLists.count)")
            print("   - Filtered month ItemLists: \(filtered.count)")
            currentMonthItemLists = filtered
        }
    }

    private func refreshSelectedMonthTotal() {
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { total, itemList in
            total + (itemListTotals[itemList.id] ?? 0)
        }
    }
    
    private func getItemListData(_ itemList: SDItemList) async -> (id: UUID, paidTotal: Double, unpaidTotal: Double, count: Int, paidStatus: ItemListPaidStatus, rowStatus: ItemListRowStatus) {
        let cacheKey = itemListDataCacheKey(for: itemList)

        if let cached: CachedItemListData = cacheManager.getCachedCalculation(for: cacheKey) {
            return (itemList.id, cached.paidTotal, cached.unpaidTotal, cached.count, cached.paidStatus, cached.rowStatus)
        }

        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let paidItems = items.filter { $0.isPaid }
            let unpaidItems = items.filter { !$0.isPaid }
            let paidTotal = paidItems.reduce(0.0) { acc, item in
                let value = item.totalAmount
                return value.isFinite ? acc + value : acc
            }
            let unpaidTotal = unpaidItems.reduce(0.0) { acc, item in
                let value = item.totalAmount
                return value.isFinite ? acc + value : acc
            }
            let totalUnits = items.reduce(0) { $0 + $1.quantity }
            let paidStatus: ItemListPaidStatus
            if items.isEmpty || paidItems.isEmpty {
                paidStatus = .none
            } else if paidItems.count == items.count {
                paidStatus = .all
            } else {
                paidStatus = .partial
            }
            let rowStatus = makeRowStatus(
                totalAmount: paidTotal + unpaidTotal,
                itemCount: totalUnits,
                paidStatus: paidStatus
            )
            let result = CachedItemListData(
                paidTotal: max(0, paidTotal.isFinite ? paidTotal : 0.0),
                unpaidTotal: max(0, unpaidTotal.isFinite ? unpaidTotal : 0.0),
                count: totalUnits,
                paidStatus: paidStatus,
                rowStatus: rowStatus
            )
            cacheManager.cacheCalculation(result, for: cacheKey)
            return (itemList.id, result.paidTotal, result.unpaidTotal, result.count, result.paidStatus, result.rowStatus)
        } catch {
            return (itemList.id, 0.0, 0.0, 0, .none, .neutral)
        }
    }

    private func makeRowStatus(
        totalAmount _: Double,
        itemCount: Int,
        paidStatus: ItemListPaidStatus
    ) -> ItemListRowStatus {
        if itemCount == 0 {
            return .neutral
        }

        switch paidStatus {
        case .none:
            return .unpaid
        case .partial:
            return .partial
        case .all:
            return .paid
        }
    }

    private func filteredItemLists(from source: [SDItemList]) -> [SDItemList] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return source }

        return source.filter { searchSummary(for: $0, query: query) != nil }
    }

    private func searchSummary(for itemList: SDItemList) -> ItemListSearchSummary? {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return searchSummary(for: itemList, query: query)
    }

    private func searchSummary(for itemList: SDItemList, query: String) -> ItemListSearchSummary? {
        guard !query.isEmpty else { return nil }

        let listMatched = itemList.itemListDescription.localizedCaseInsensitiveContains(query)
        let matchedItems = itemList.items.filter {
            $0.itemDescription.localizedCaseInsensitiveContains(query)
        }

        guard listMatched || !matchedItems.isEmpty else { return nil }

        let matchedSubtotal = matchedItems.reduce(0.0) { partialResult, item in
            let value = item.totalAmount
            guard value.isFinite else { return partialResult }
            return partialResult + value
        }
        let matchedUnpaidSubtotal = matchedItems.reduce(0.0) { partialResult, item in
            guard !item.isPaid else { return partialResult }
            let value = item.totalAmount
            guard value.isFinite else { return partialResult }
            return partialResult + value
        }

        return ItemListSearchSummary(
            listMatched: listMatched,
            matchedItemCount: matchedItems.count,
            matchedSubtotal: matchedSubtotal.isFinite ? matchedSubtotal : 0.0,
            matchedUnpaidSubtotal: matchedUnpaidSubtotal.isFinite ? matchedUnpaidSubtotal : 0.0
        )
    }

    private func itemListDataCacheKey(for itemList: SDItemList) -> String {
        let versionDate = itemList.lastModifiedAt ?? itemList.createdAt
        return "dashboard_item_list_data_\(itemList.id.uuidString)_\(versionDate.timeIntervalSince1970)"
    }

    func getItemListTotal(_ itemList: SDItemList) async -> Double {
        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let total = items.reduce(0.0) { total, item in
                let value = item.totalAmount
                guard value.isFinite else { return total }
                return total + value
            }
            guard total.isFinite else { return 0.0 }
            return total
        } catch {
            return 0.0
        }
    }

    func getFormattedItemListTotal(_ itemList: SDItemList) async -> String {
        let total = await getItemListTotal(itemList)
        guard total.isFinite else { return "€0.00" }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "€0.00"
    }

    func deleteItemList(_ itemList: SDItemList) async {
        await removeItemList(itemList)
        do {
            try await deleteItemListUseCase.execute(id: itemList.id)
        } catch {
            await loadDashboardData()
        }
    }

    private func removeItemList(_ itemList: SDItemList) async {
        let currentItemLists = itemLists

        guard let index = currentItemLists.firstIndex(where: { $0.id == itemList.id }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }

        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)

        withAnimation(.easeInOut(duration: 0.25)) {
            itemLists = updatedItemLists
        }

        await calculateTotalSpent()
    }

    func updateItemList(_ itemList: SDItemList) async {
        print("✏️ DashboardViewModel: Updating ItemList in UI cache")

        // Re-sort since date may have changed (SD* reference type, object is already mutated)
        let cal = Calendar.current
        itemLists = itemLists.sorted {
            let d0 = cal.startOfDay(for: $0.date)
            let d1 = cal.startOfDay(for: $1.date)
            return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
        }

        await calculateTotalSpent()
    }

    private func isItemListInCurrentContext(_ itemList: SDItemList) -> Bool {
        guard let currentGroup = currentGroup else { return false }
        return currentGroup.id == itemList.group?.id
    }

    func getCurrentMonthItemLists() -> [SDItemList] {
        let calendar = Calendar.current
        return itemLists.filter { itemList in
            calendar.isDate(itemList.date, equalTo: selectedMonthAnchor, toGranularity: .month)
        }
    }

    func filteredItemLists(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> [SDItemList] {
        let source: [SDItemList] = switch range {
        case .today:
            filteredTodayItemLists
        case .month:
            filteredMonthItemLists
        }

        return source.filter { $0.category?.id == categoryId }
    }

    func categoryBox(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> DashboardCategoryBoxData? {
        let source: [DashboardCategoryBoxData] = switch range {
        case .today:
            todayCategoryBoxes
        case .month:
            monthCategoryBoxes
        }

        return source.first { $0.categoryId == categoryId }
    }

    private func makeCategoryBoxes(from source: [SDItemList], range: DashboardCategoryRange) -> [DashboardCategoryBoxData] {
        var grouped: [UUID: CategoryAggregate] = [:]

        for itemList in source {
            guard let category = itemList.category else { continue }

            let metadata = categoryMetadata(for: category)
            let paidAmount = itemListTotals[itemList.id] ?? 0.0
            let unpaidAmount = itemListUnpaidTotals[itemList.id] ?? 0.0
            let itemCount = itemListCounts[itemList.id] ?? itemList.itemCount

            if var aggregate = grouped[category.id] {
                aggregate.paidAmount += paidAmount
                aggregate.unpaidAmount += unpaidAmount
                aggregate.itemListCount += 1
                aggregate.itemCount += itemCount
                grouped[category.id] = aggregate
            } else {
                grouped[category.id] = CategoryAggregate(
                    categoryId: category.id,
                    categoryName: metadata.name,
                    categoryColorHex: metadata.color,
                    categoryIcon: metadata.icon,
                    paidAmount: paidAmount,
                    unpaidAmount: unpaidAmount,
                    itemListCount: 1,
                    itemCount: itemCount
                )
            }
        }

        let boxes = grouped.values.map { aggregate in
            DashboardCategoryBoxData(
                categoryId: aggregate.categoryId,
                categoryName: aggregate.categoryName,
                categoryColorHex: aggregate.categoryColorHex,
                categoryIcon: aggregate.categoryIcon,
                paidAmount: aggregate.paidAmount,
                unpaidAmount: aggregate.unpaidAmount,
                totalAmount: aggregate.paidAmount + aggregate.unpaidAmount,
                itemListCount: aggregate.itemListCount,
                itemCount: aggregate.itemCount,
                sizeTier: .small,
                range: range
            )
        }
        .sorted {
            if abs($0.paidAmount - $1.paidAmount) > 0.000_001 {
                return $0.paidAmount > $1.paidAmount
            }
            return $0.categoryName.localizedCaseInsensitiveCompare($1.categoryName) == .orderedAscending
        }

        return applySizeTiers(to: boxes)
    }

    private func applySizeTiers(to boxes: [DashboardCategoryBoxData]) -> [DashboardCategoryBoxData] {
        guard !boxes.isEmpty else { return [] }
        guard boxes.count > 1 else {
            return boxes.map { box in
                DashboardCategoryBoxData(
                    categoryId: box.categoryId,
                    categoryName: box.categoryName,
                    categoryColorHex: box.categoryColorHex,
                    categoryIcon: box.categoryIcon,
                    paidAmount: box.paidAmount,
                    unpaidAmount: box.unpaidAmount,
                    totalAmount: box.totalAmount,
                    itemListCount: box.itemListCount,
                    itemCount: box.itemCount,
                    sizeTier: .large,
                    range: box.range
                )
            }
        }

        let maxAmount = boxes.map(\.paidAmount).max() ?? 0.0
        guard maxAmount > 0.000_001 else {
            return boxes.enumerated().map { index, box in
                DashboardCategoryBoxData(
                    categoryId: box.categoryId,
                    categoryName: box.categoryName,
                    categoryColorHex: box.categoryColorHex,
                    categoryIcon: box.categoryIcon,
                    paidAmount: box.paidAmount,
                    unpaidAmount: box.unpaidAmount,
                    totalAmount: box.totalAmount,
                    itemListCount: box.itemListCount,
                    itemCount: box.itemCount,
                    sizeTier: index == 0 ? .large : .small,
                    range: box.range
                )
            }
        }

        return boxes.enumerated().map { index, box in
            let ratio = box.paidAmount / maxAmount
            let sizeTier: DashboardCategoryBoxSize
            if index == 0 || ratio >= 0.70 {
                sizeTier = .large
            } else if ratio >= 0.35 {
                sizeTier = .medium
            } else {
                sizeTier = .small
            }

            return DashboardCategoryBoxData(
                categoryId: box.categoryId,
                categoryName: box.categoryName,
                categoryColorHex: box.categoryColorHex,
                categoryIcon: box.categoryIcon,
                paidAmount: box.paidAmount,
                unpaidAmount: box.unpaidAmount,
                totalAmount: box.totalAmount,
                itemListCount: box.itemListCount,
                itemCount: box.itemCount,
                sizeTier: sizeTier,
                range: box.range
            )
        }
    }

    private func categoryMetadata(for category: SDCategory) -> CategoryMetadata {
        if let cached = categories[category.id] {
            return cached
        }

        return (category.name, category.color, category.icon)
    }
}

// MARK: - Supporting Types

private enum TotalSpentOperation {
    case add
    case remove
}
