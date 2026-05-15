import XCTest
@testable import OMOMoney

@MainActor
final class CalculateItemListTotalsUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var useCase: CalculateItemListTotalsUseCase!
    private var group: SDGroup!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        CacheManager.shared.clearAllCaches()
        let fetchItemsUseCase = DefaultFetchItemsUseCase(itemRepository: swiftData.makeItemRepository())
        useCase = DefaultCalculateItemListTotalsUseCase(
            fetchItemsUseCase: fetchItemsUseCase,
            cacheManager: .shared
        )
        group = try swiftData.insertGroup()
    }

    override func tearDown() {
        CacheManager.shared.clearAllCaches()
        useCase = nil
        group = nil
        swiftData = nil
    }

    // MARK: - Empty states

    func testEmptyItemLists_TotalSpentIsZero() async {
        let result = await useCase.execute(itemLists: [])

        XCTAssertEqual(result.totalSpent, 0.0)
        XCTAssertTrue(result.itemListTotals.isEmpty)
    }

    func testItemListWithNoItems_StatusIsNone_RowStatusNeutral() async throws {
        let itemList = try swiftData.insertItemList(group: group)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListPaidStatus[itemList.id], ItemListPaidStatus.none)
        XCTAssertEqual(result.itemListRowStatus[itemList.id], .neutral)
        XCTAssertEqual(result.itemListTotals[itemList.id], 0.0)
        XCTAssertEqual(result.itemListCounts[itemList.id], 0)
    }

    // MARK: - Paid status

    func testAllItemsPaid_PaidStatusAll_RowStatusPaid() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 10.0, isPaid: true, itemList: itemList)
        try swiftData.insertItem(amount: 20.0, isPaid: true, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListPaidStatus[itemList.id], .all)
        XCTAssertEqual(result.itemListRowStatus[itemList.id], .paid)
    }

    func testAllItemsUnpaid_PaidStatusNone_RowStatusUnpaid() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 10.0, isPaid: false, itemList: itemList)
        try swiftData.insertItem(amount: 20.0, isPaid: false, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListPaidStatus[itemList.id], ItemListPaidStatus.none)
        XCTAssertEqual(result.itemListRowStatus[itemList.id], .unpaid)
    }

    func testMixedItems_PaidStatusPartial_RowStatusPartial() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 10.0, isPaid: true, itemList: itemList)
        try swiftData.insertItem(amount: 20.0, isPaid: false, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListPaidStatus[itemList.id], .partial)
        XCTAssertEqual(result.itemListRowStatus[itemList.id], .partial)
    }

    // MARK: - Totals

    func testPaidTotalIsCorrect() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 10.0, isPaid: true, itemList: itemList)
        try swiftData.insertItem(amount: 15.0, isPaid: true, itemList: itemList)
        try swiftData.insertItem(amount: 5.0, isPaid: false, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListTotals[itemList.id] ?? 0, 25.0, accuracy: 0.001)
        XCTAssertEqual(result.itemListUnpaidTotals[itemList.id] ?? 0, 5.0, accuracy: 0.001)
    }

    func testQuantityMultipliesAmount() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(description: "x3", amount: 5.0, quantity: 3, isPaid: true, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListTotals[itemList.id] ?? 0, 15.0, accuracy: 0.001)
    }

    func testTotalSpentIsSumOfAllPaidTotals() async throws {
        let list1 = try swiftData.insertItemList(description: "Lista 1", group: group)
        let list2 = try swiftData.insertItemList(description: "Lista 2", group: group)
        try swiftData.insertItem(amount: 30.0, isPaid: true, itemList: list1)
        try swiftData.insertItem(amount: 20.0, isPaid: true, itemList: list2)

        let result = await useCase.execute(itemLists: [list1, list2])

        XCTAssertEqual(result.totalSpent, 50.0, accuracy: 0.001)
    }

    func testUnpaidItemsExcludedFromTotalSpent() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 100.0, isPaid: false, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.totalSpent, 0.0, accuracy: 0.001)
    }

    // MARK: - Item count

    func testItemCountReflectsQuantity() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(quantity: 2, isPaid: false, itemList: itemList)
        try swiftData.insertItem(quantity: 3, isPaid: true, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result.itemListCounts[itemList.id], 5)
    }

    // MARK: - Search items

    func testSearchItemsPopulatedCorrectly() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(description: "Leche", amount: 1.20, isPaid: true, itemList: itemList)
        try swiftData.insertItem(description: "Pan", amount: 0.80, isPaid: false, itemList: itemList)

        let result = await useCase.execute(itemLists: [itemList])

        let searchItems = result.searchItems[itemList.id] ?? []
        XCTAssertEqual(searchItems.count, 2)
        XCTAssertTrue(searchItems.contains { $0.description == "Leche" && $0.isPaid })
        XCTAssertTrue(searchItems.contains { $0.description == "Pan" && !$0.isPaid })
    }

    // MARK: - Cache

    func testSecondCallUsesCache_NoExtraFetches() async throws {
        let itemList = try swiftData.insertItemList(group: group)
        try swiftData.insertItem(amount: 10.0, isPaid: true, itemList: itemList)

        let result1 = await useCase.execute(itemLists: [itemList])
        let result2 = await useCase.execute(itemLists: [itemList])

        XCTAssertEqual(result1.totalSpent, result2.totalSpent, accuracy: 0.001)
        XCTAssertEqual(result1.itemListPaidStatus[itemList.id], result2.itemListPaidStatus[itemList.id])
    }
}
