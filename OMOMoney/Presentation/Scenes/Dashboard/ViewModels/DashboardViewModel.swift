import Foundation
import SwiftUI

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
    private typealias CategoryMetadata = (name: String, color: String, icon: String)
    private typealias ItemPaidSnapshot = (id: UUID, isPaid: Bool)
    private typealias ItemListCollectionSnapshot = (
        itemLists: [SDItemList],
        itemListTotals: [UUID: Double],
        itemListUnpaidTotals: [UUID: Double],
        itemListCounts: [UUID: Int],
        itemListPaidStatus: [UUID: ItemListPaidStatus],
        itemListRowStatus: [UUID: ItemListRowStatus],
        totalSpent: Double,
        todayTotal: Double,
        todayUnpaidTotal: Double,
        currentMonthTotal: Double,
        currentMonthUnpaidTotal: Double
    )

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

    var isCustomMonthFilterActive: Bool {
        !Calendar.current.isDate(selectedMonthAnchor, equalTo: Date(), toGranularity: .month)
    }

    var hasActiveSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var selectedMonthTitle: String {
        monthTitleFormatter.string(from: selectedMonthAnchor).capitalized(with: Locale.current)
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
    private let calculateItemListTotalsUseCase: CalculateItemListTotalsUseCase

    // MARK: - Cache
    private let cacheManager = CacheManager.shared
    private var cachedSearchItems: [UUID: [ItemListTotalsResult.SearchItemData]] = [:]
    private var paidToggleTasks: [UUID: Task<Void, Never>] = [:]
    private var _currencyFormatter: NumberFormatter?
    private var _currencyFormatterCode: String = ""
    private let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "LLLL yyyy"
        return f
    }()

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
        deleteGroupUseCase: DeleteGroupUseCase,
        calculateItemListTotalsUseCase: CalculateItemListTotalsUseCase
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
        self.calculateItemListTotalsUseCase = calculateItemListTotalsUseCase
    }
    
    // MARK: - Public Methods
    
    func loadDashboardData() async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let user = try await getCurrentUserUseCase.execute() else {
                errorMessage = "No user found. Please create a user first."
                isLoading = false
                return
            }

            let groups = try await fetchGroupsForUserUseCase.execute(userId: user.id)
            guard let firstGroup = groups.first else {
                errorMessage = "No groups found. Please create a group first."
                isLoading = false
                return
            }

            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: firstGroup.id)

            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: firstGroup.id)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }

            currentUser = user
            currentGroup = firstGroup
            availableGroups = groups
            selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
            itemLists = fetchedItemLists
            categories = categoriesDict

            await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))

            isLoading = false
            
        } catch {
            errorMessage = "Error loading dashboard data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func refreshData() async {
        
        isRefreshing = true
        
        do {
            guard let group = currentGroup else {
                isRefreshing = false
                return
            }
            
            let groupId = group.id

            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)
            
            
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

            await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))

            isRefreshing = false
            
        } catch {
            isRefreshing = false
        }
    }

    func addExpense() {
    }
    
    // MARK: - Group Management
    
    func changeGroup(to newGroup: SDGroup) async {
        guard newGroup.id != currentGroup?.id else {
            return
        }


        isChangingGroup = true

        do {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let groupId = newGroup.id
            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)

            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }

            currentGroup = newGroup
            selectedMonthAnchor = Calendar.current.startOfMonth(for: Date())
            itemListTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListUnpaidTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListCounts = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0) })
            itemListPaidStatus = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, ItemListPaidStatus.none) })
            itemListRowStatus = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, ItemListRowStatus.neutral) })
            itemLists = fetchedItemLists
            categories = categoriesDict

            await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))

            isChangingGroup = false
        } catch {
            isChangingGroup = false
        }
    }
    
    func refreshAvailableGroups() async {
        guard let user = currentUser else {
            return
        }
        

        do {
            let userId = user.id
            let groups = try await fetchGroupsForUserUseCase.execute(userId: userId)

            availableGroups = groups
        } catch {
        }
    }
    
    func addGroup(_ newGroup: SDGroup) {

        guard !availableGroups.contains(where: { $0.id == newGroup.id }) else {
            return
        }

        availableGroups.append(newGroup)
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
        guard let currentGroupId = currentGroup?.id else {
            return
        }

        if itemList.group?.id != currentGroupId {
            return
        }

        if itemLists.contains(where: { $0.id == itemList.id }) {
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
        itemListPaidStatus[itemList.id] = ItemListPaidStatus.none
        itemListRowStatus[itemList.id] = .neutral

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            itemLists = sortedItemLists
        }
        await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))

    }

    @MainActor
    func clearCache() async {
        cacheManager.clearAllCaches()
    }
    
    func togglePaid(for itemList: SDItemList) {
        let itemCount = itemListCounts[itemList.id] ?? 0

        guard itemCount > 0 else {
            toast = ToastMessage(LocalizationKey.Dashboard.emptyEntryToast.localized, type: .info)
            return
        }

        paidToggleTasks[itemList.id]?.cancel()
        paidToggleTasks[itemList.id] = Task { @MainActor in
            let currentItems = await currentItemsSnapshot(for: itemList)
            let previousStates = makePaidSnapshot(from: currentItems)
            let currentStatus = itemListPaidStatus[itemList.id] ?? .none
            let newValue = currentStatus == .all ? false : true

            applyBulkPaidState(
                newValue,
                to: currentItems,
                in: itemList,
                itemCount: itemCount
            )
            showBulkToggleToast(
                for: itemList,
                itemCount: itemCount,
                newValue: newValue,
                previousStates: previousStates
            )

            defer { paidToggleTasks[itemList.id] = nil }

            try? await toggleAllItemsPaidInListUseCase.execute(itemListId: itemList.id, isPaid: newValue)
            await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))
        }
    }

    private func undoTogglePaid(
        for itemList: SDItemList,
        previousStates: [ItemPaidSnapshot]
    ) async {
        if let pendingTask = paidToggleTasks[itemList.id] {
            await pendingTask.value
        }

        await restorePaidSnapshot(previousStates, for: itemList)
        await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))
        toast = ToastMessage(LocalizationKey.Dashboard.changeUndone.localized, type: .info)
    }

    func forceRefresh() async {
        await clearCache()
        await loadDashboardData()
    }
    
    // MARK: - Private Methods

    private func makeItemListCollectionSnapshot() -> ItemListCollectionSnapshot {
        (
            itemLists: itemLists,
            itemListTotals: itemListTotals,
            itemListUnpaidTotals: itemListUnpaidTotals,
            itemListCounts: itemListCounts,
            itemListPaidStatus: itemListPaidStatus,
            itemListRowStatus: itemListRowStatus,
            totalSpent: totalSpent,
            todayTotal: todayTotal,
            todayUnpaidTotal: todayUnpaidTotal,
            currentMonthTotal: currentMonthTotal,
            currentMonthUnpaidTotal: currentMonthUnpaidTotal
        )
    }

    private func restoreItemListCollectionSnapshot(_ snapshot: ItemListCollectionSnapshot) {
        itemLists = snapshot.itemLists
        itemListTotals = snapshot.itemListTotals
        itemListUnpaidTotals = snapshot.itemListUnpaidTotals
        itemListCounts = snapshot.itemListCounts
        itemListPaidStatus = snapshot.itemListPaidStatus
        itemListRowStatus = snapshot.itemListRowStatus
        totalSpent = snapshot.totalSpent
        todayTotal = snapshot.todayTotal
        todayUnpaidTotal = snapshot.todayUnpaidTotal
        currentMonthTotal = snapshot.currentMonthTotal
        currentMonthUnpaidTotal = snapshot.currentMonthUnpaidTotal
    }

    func refreshTotals() async {
        await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))
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

    private func makePaidSnapshot(from items: [SDItem]) -> [ItemPaidSnapshot] {
        items.map { (id: $0.id, isPaid: $0.isPaid) }
    }

    private func applyBulkPaidState(
        _ isPaid: Bool,
        to items: [SDItem],
        in itemList: SDItemList,
        itemCount: Int
    ) {
        itemList.lastModifiedAt = Date()
        itemListPaidStatus[itemList.id] = isPaid ? ItemListPaidStatus.all : ItemListPaidStatus.none
        items.forEach { $0.isPaid = isPaid }
        itemListRowStatus[itemList.id] = makeRowStatus(
            totalAmount: itemList.totalAmount,
            itemCount: itemCount,
            paidStatus: itemListPaidStatus[itemList.id] ?? ItemListPaidStatus.none
        )
    }

    private func showBulkToggleToast(
        for itemList: SDItemList,
        itemCount: Int,
        newValue: Bool,
        previousStates: [ItemPaidSnapshot]
    ) {
        guard itemCount > 1 else {
            toast = nil
            return
        }

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
    }

    private func currentItemsSnapshot(for itemList: SDItemList) async -> [SDItem] {
        if let fetchedItems = try? await fetchItemsUseCase.execute(forItemListId: itemList.id), !fetchedItems.isEmpty {
            return fetchedItems
        }
        return itemList.items
    }

    private func restorePaidSnapshot(
        _ snapshot: [ItemPaidSnapshot],
        for itemList: SDItemList
    ) async {
        let currentItems = await currentItemsSnapshot(for: itemList)

        for state in snapshot {
            currentItems.first { $0.id == state.id }?.isPaid = state.isPaid
            try? await toggleItemPaidUseCase.execute(itemId: state.id, isPaid: state.isPaid)
        }

        itemList.lastModifiedAt = Date()
        let restoredStatus = paidStatus(from: snapshot)
        itemListPaidStatus[itemList.id] = restoredStatus
        itemListRowStatus[itemList.id] = makeRowStatus(
            totalAmount: itemList.totalAmount,
            itemCount: snapshot.count,
            paidStatus: restoredStatus
        )
    }

    private func makeRowStatus(totalAmount _: Double, itemCount: Int, paidStatus: ItemListPaidStatus) -> ItemListRowStatus {
        guard itemCount > 0 else { return .neutral }
        switch paidStatus {
        case .none: return .unpaid
        case .partial: return .partial
        case .all: return .paid
        }
    }

    private func paidStatus(from snapshot: [ItemPaidSnapshot]) -> ItemListPaidStatus {
        let restoredPaidCount = snapshot.filter { $0.isPaid }.count

        if snapshot.isEmpty || restoredPaidCount == 0 {
            return .none
        }
        if restoredPaidCount == snapshot.count {
            return .all
        }
        return .partial
    }

    private func applyTotals(_ result: ItemListTotalsResult) {
        itemListTotals = result.itemListTotals
        itemListUnpaidTotals = result.itemListUnpaidTotals
        itemListCounts = result.itemListCounts
        itemListPaidStatus = result.itemListPaidStatus
        itemListRowStatus = result.itemListRowStatus
        cachedSearchItems = result.searchItems
        totalSpent = result.totalSpent
        todayTotal = todayItemLists.reduce(0.0) { $0 + (result.itemListTotals[$1.id] ?? 0) }
        todayUnpaidTotal = todayItemLists.reduce(0.0) { $0 + (result.itemListUnpaidTotals[$1.id] ?? 0) }
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { $0 + (result.itemListTotals[$1.id] ?? 0) }
        currentMonthUnpaidTotal = currentMonthItemLists.reduce(0.0) { $0 + (result.itemListUnpaidTotals[$1.id] ?? 0) }
    }

    private func recomputeTotalsFromCurrentState() {
        todayTotal = todayItemLists.reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        todayUnpaidTotal = todayItemLists.reduce(0.0) { $0 + (itemListUnpaidTotals[$1.id] ?? 0) }
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        currentMonthUnpaidTotal = currentMonthItemLists.reduce(0.0) { $0 + (itemListUnpaidTotals[$1.id] ?? 0) }

        let newTotal = itemLists.reduce(0.0) { partialResult, itemList in
            let value = itemListTotals[itemList.id] ?? 0.0
            guard value.isFinite else { return partialResult }
            return partialResult + value
        }

        totalSpent = newTotal.isFinite ? max(0, newTotal) : 0.0
    }
    
    // MARK: - Helper Methods

    private var currencyFormatter: NumberFormatter {
        let code = currentGroup?.currency ?? "EUR"
        if let cached = _currencyFormatter, _currencyFormatterCode == code {
            return cached
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = code
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        _currencyFormatter = formatter
        _currencyFormatterCode = code
        return formatter
    }

    func formattedPaid(for itemList: SDItemList) -> String {
        guard let total = itemListTotals[itemList.id] else { return "€0.00" }
        return currencyFormatter.string(from: NSNumber(value: total)) ?? "€0.00"
    }

    func formattedUnpaid(for itemList: SDItemList) -> String? {
        guard let status = itemListPaidStatus[itemList.id],
              status != .all,
              let unpaid = itemListUnpaidTotals[itemList.id],
              unpaid > 0 else { return nil }
        return currencyFormatter.string(from: NSNumber(value: unpaid))
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
        let paidMatchedAmount = summary.matchedSubtotal - summary.matchedUnpaidSubtotal
        let visiblePaidAmount = max(0, paidMatchedAmount.isFinite ? paidMatchedAmount : 0.0)
        return currencyFormatter.string(from: NSNumber(value: visiblePaidAmount)) ?? "€0.00"
    }

    func formattedSearchMatchedUnpaid(for itemList: SDItemList) -> String? {
        guard let summary = searchSummary(for: itemList), summary.hasItemMatches else { return nil }
        guard summary.matchedUnpaidSubtotal > 0.000_001 else { return nil }
        return currencyFormatter.string(from: NSNumber(value: summary.matchedUnpaidSubtotal))
    }

    func visiblePaidAmount(for itemList: SDItemList) -> Double {
        if let summary = searchSummary(for: itemList), summary.hasItemMatches {
            let paidMatchedAmount = summary.matchedSubtotal - summary.matchedUnpaidSubtotal
            return max(0, paidMatchedAmount.isFinite ? paidMatchedAmount : 0.0)
        }

        return max(0, itemListTotals[itemList.id] ?? 0.0)
    }

    func formattedVisibleDayPaidTotal(for date: Date, from itemLists: [SDItemList]) -> String {
        let calendar = Calendar.current
        let dayTotal = itemLists
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0.0) { total, itemList in
                total + visiblePaidAmount(for: itemList)
            }

        return formattedCurrency(dayTotal)
    }

    func formattedTotal(for date: Date) -> String {
        let cal = Calendar.current
        let dayTotal = itemLists
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        return currencyFormatter.string(from: NSNumber(value: dayTotal)) ?? "€0.00"
    }

    func formattedCurrency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "€0.00"
    }

    func formattedAmount(for box: DashboardCategoryBoxData) -> String {
        formattedCurrency(box.paidAmount)
    }

    func formattedUnpaidAmount(for box: DashboardCategoryBoxData) -> String? {
        guard box.unpaidAmount > 0.000_001 else { return nil }
        return formattedCurrency(box.unpaidAmount)
    }

    var formattedTodayTotal: String {
        currencyFormatter.string(from: NSNumber(value: todayTotal)) ?? "€0.00"
    }

    func formattedCachedMonthTotal() -> String {
        currencyFormatter.string(from: NSNumber(value: currentMonthTotal)) ?? "€0.00"
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
        return currencyFormatter.string(from: NSNumber(value: monthTotal)) ?? "€0.00"
    }

    var formattedTotalSpent: String {
        guard totalSpent.isFinite else { return "€0.00" }
        return currencyFormatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
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
            currentMonthItemLists = filtered
        }
    }

    private func refreshSelectedMonthTotal() {
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { total, itemList in
            total + (itemListTotals[itemList.id] ?? 0)
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
        let matchedItems = currentSearchItems(for: itemList).filter {
            $0.description.localizedCaseInsensitiveContains(query)
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

    private func currentSearchItems(for itemList: SDItemList) -> [ItemListTotalsResult.SearchItemData] {
        if let cached = cachedSearchItems[itemList.id] { return cached }
        return itemList.items.map {
            ItemListTotalsResult.SearchItemData(
                description: $0.itemDescription,
                totalAmount: $0.totalAmount,
                isPaid: $0.isPaid
            )
        }
    }

    func deleteItemList(_ itemList: SDItemList) {
        let snapshot = makeItemListCollectionSnapshot()
        removeItemList(itemList)
        Task {
            do {
                try await deleteItemListUseCase.execute(id: itemList.id)
                calculateItemListTotalsUseCase.clearCache(for: itemList)
            } catch {
                restoreItemListCollectionSnapshot(snapshot)
            }
        }
    }

    private func removeItemList(_ itemList: SDItemList) {
        let currentItemLists = itemLists

        guard let index = currentItemLists.firstIndex(where: { $0.id == itemList.id }) else {
            return
        }

        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            itemLists = updatedItemLists
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            itemListTotals[itemList.id] = nil
            itemListUnpaidTotals[itemList.id] = nil
            itemListCounts[itemList.id] = nil
            itemListPaidStatus[itemList.id] = nil
            itemListRowStatus[itemList.id] = nil
            recomputeTotalsFromCurrentState()
        }
    }

    func updateItemList(_ itemList: SDItemList) async {

        // Re-sort since date may have changed (SD* reference type, object is already mutated)
        let cal = Calendar.current
        itemLists = itemLists.sorted {
            let d0 = cal.startOfDay(for: $0.date)
            let d1 = cal.startOfDay(for: $1.date)
            return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
        }

        await applyTotals(calculateItemListTotalsUseCase.execute(itemLists: itemLists))
    }

    private func isItemListInCurrentContext(_ itemList: SDItemList) -> Bool {
        guard let currentGroup = currentGroup else { return false }
        return currentGroup.id == itemList.group?.id
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

    func hasCategoryContext(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> Bool {
        categoryBox(forCategoryId: categoryId, in: range) != nil ||
        categoryMetadata(forCategoryId: categoryId) != nil
    }

    func categoryDisplayName(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> String? {
        categoryBox(forCategoryId: categoryId, in: range)?.categoryName ??
        categoryMetadata(forCategoryId: categoryId)?.name
    }

    func categoryDisplayIcon(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> String? {
        categoryBox(forCategoryId: categoryId, in: range)?.categoryIcon ??
        categoryMetadata(forCategoryId: categoryId)?.icon
    }

    func categoryDisplayColorHex(forCategoryId categoryId: UUID, in range: DashboardCategoryRange) -> String? {
        categoryBox(forCategoryId: categoryId, in: range)?.categoryColorHex ??
        categoryMetadata(forCategoryId: categoryId)?.color
    }

    private func categoryMetadata(forCategoryId categoryId: UUID) -> CategoryMetadata? {
        if let category = categories[categoryId] {
            return (category.name, category.color, category.icon)
        }

        if let category = itemLists.first(where: { $0.category?.id == categoryId })?.category {
            return categoryMetadata(for: category)
        }

        return nil
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
        return (category.name, category.color, category.icon)
    }
}

// MARK: - Supporting Types

private enum TotalSpentOperation {
    case add
    case remove
}
