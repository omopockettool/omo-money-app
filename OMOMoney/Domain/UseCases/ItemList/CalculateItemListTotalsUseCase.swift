import Foundation

struct ItemListTotalsResult {
    struct SearchItemData {
        let description: String
        let totalAmount: Double
        let isPaid: Bool
    }

    let itemListTotals: [UUID: Double]
    let itemListUnpaidTotals: [UUID: Double]
    let itemListCounts: [UUID: Int]
    let itemListPaidStatus: [UUID: ItemListPaidStatus]
    let itemListRowStatus: [UUID: ItemListRowStatus]
    let searchItems: [UUID: [SearchItemData]]
    let totalSpent: Double
}

@MainActor
protocol CalculateItemListTotalsUseCase {
    func execute(itemLists: [SDItemList]) async -> ItemListTotalsResult
    func clearCache(for itemList: SDItemList)
}

@MainActor
final class DefaultCalculateItemListTotalsUseCase: CalculateItemListTotalsUseCase {
    private struct CachedListData {
        let paidTotal: Double
        let unpaidTotal: Double
        let count: Int
        let paidStatus: ItemListPaidStatus
        let rowStatus: ItemListRowStatus
        let searchItems: [ItemListTotalsResult.SearchItemData]
    }

    private let fetchItemsUseCase: FetchItemsUseCase
    private let cacheManager: CacheManager

    init(fetchItemsUseCase: FetchItemsUseCase, cacheManager: CacheManager) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.cacheManager = cacheManager
    }

    func execute(itemLists: [SDItemList]) async -> ItemListTotalsResult {
        typealias PerList = (
            id: UUID,
            paidTotal: Double,
            unpaidTotal: Double,
            count: Int,
            paidStatus: ItemListPaidStatus,
            rowStatus: ItemListRowStatus,
            searchItems: [ItemListTotalsResult.SearchItemData]
        )

        let results: [PerList] = await withTaskGroup(of: PerList.self) { group in
            var items: [PerList] = []
            for itemList in itemLists {
                group.addTask { await self.computeListData(itemList) }
            }
            for await result in group { items.append(result) }
            return items
        }

        let totals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidTotal) })
        let unpaidTotals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.unpaidTotal) })
        let counts = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.count) })
        let paidStatuses = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidStatus) })
        let rowStatuses = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.rowStatus) })
        let searchItems = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.searchItems) })

        let rawTotal = totals.values.reduce(0.0) { acc, val in val.isFinite ? acc + val : acc }
        let totalSpent = rawTotal.isFinite ? max(0, rawTotal) : 0.0

        return ItemListTotalsResult(
            itemListTotals: totals,
            itemListUnpaidTotals: unpaidTotals,
            itemListCounts: counts,
            itemListPaidStatus: paidStatuses,
            itemListRowStatus: rowStatuses,
            searchItems: searchItems,
            totalSpent: totalSpent
        )
    }

    func clearCache(for itemList: SDItemList) {
        cacheManager.clearCalculationCache(for: cacheKey(for: itemList))
    }

    private func computeListData(_ itemList: SDItemList) async -> (
        id: UUID,
        paidTotal: Double,
        unpaidTotal: Double,
        count: Int,
        paidStatus: ItemListPaidStatus,
        rowStatus: ItemListRowStatus,
        searchItems: [ItemListTotalsResult.SearchItemData]
    ) {
        let key = cacheKey(for: itemList)

        if let cached: CachedListData = cacheManager.getCachedCalculation(for: key) {
            return (itemList.id, cached.paidTotal, cached.unpaidTotal, cached.count, cached.paidStatus, cached.rowStatus, cached.searchItems)
        }

        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let paidItems = items.filter { $0.isPaid }
            let unpaidItems = items.filter { !$0.isPaid }

            let paidTotal = paidItems.reduce(0.0) { acc, item in
                let v = item.totalAmount; return v.isFinite ? acc + v : acc
            }
            let unpaidTotal = unpaidItems.reduce(0.0) { acc, item in
                let v = item.totalAmount; return v.isFinite ? acc + v : acc
            }
            let count = items.reduce(0) { $0 + $1.quantity }

            let paidStatus: ItemListPaidStatus
            if items.isEmpty || paidItems.isEmpty {
                paidStatus = .none
            } else if paidItems.count == items.count {
                paidStatus = .all
            } else {
                paidStatus = .partial
            }

            let rowStatus = makeRowStatus(itemCount: Int(count), paidStatus: paidStatus)
            let searchData = items.map {
                ItemListTotalsResult.SearchItemData(
                    description: $0.itemDescription,
                    totalAmount: $0.totalAmount,
                    isPaid: $0.isPaid
                )
            }

            let cached = CachedListData(
                paidTotal: max(0, paidTotal.isFinite ? paidTotal : 0.0),
                unpaidTotal: max(0, unpaidTotal.isFinite ? unpaidTotal : 0.0),
                count: Int(count),
                paidStatus: paidStatus,
                rowStatus: rowStatus,
                searchItems: searchData
            )
            cacheManager.cacheCalculation(cached, for: key)
            return (itemList.id, cached.paidTotal, cached.unpaidTotal, cached.count, cached.paidStatus, cached.rowStatus, searchData)
        } catch {
            return (itemList.id, 0.0, 0.0, 0, .none, .neutral, [])
        }
    }

    private func makeRowStatus(itemCount: Int, paidStatus: ItemListPaidStatus) -> ItemListRowStatus {
        guard itemCount > 0 else { return .neutral }
        switch paidStatus {
        case .none: return .unpaid
        case .partial: return .partial
        case .all: return .paid
        }
    }

    private func cacheKey(for itemList: SDItemList) -> String {
        let versionDate = itemList.lastModifiedAt ?? itemList.createdAt
        return "dashboard_item_list_data_\(itemList.id.uuidString)_\(versionDate.timeIntervalSince1970)"
    }
}
