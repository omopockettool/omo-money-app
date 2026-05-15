import XCTest
@testable import OMOMoney

// MARK: - DeleteItemUseCase

@MainActor
final class DeleteItemUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var deleteUseCase: DeleteItemUseCase!
    private var fetchUseCase: FetchItemsUseCase!
    private var group: SDGroup!
    private var itemList: SDItemList!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        let repo = swiftData.makeItemRepository()
        deleteUseCase = DefaultDeleteItemUseCase(itemRepository: repo)
        fetchUseCase = DefaultFetchItemsUseCase(itemRepository: repo)
        group = try swiftData.insertGroup()
        itemList = try swiftData.insertItemList(group: group)
    }

    override func tearDown() {
        deleteUseCase = nil
        fetchUseCase = nil
        itemList = nil
        group = nil
        swiftData = nil
    }

    func testDelete_ExistingItem_RemovesItFromList() async throws {
        let item = try swiftData.insertItem(description: "Café", itemList: itemList)

        try await deleteUseCase.execute(id: item.id)

        let remaining = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testDelete_OnlyDeletesTargetItem() async throws {
        let item1 = try swiftData.insertItem(description: "Café", itemList: itemList)
        try swiftData.insertItem(description: "Agua", itemList: itemList)

        try await deleteUseCase.execute(id: item1.id)

        let remaining = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.itemDescription, "Agua")
    }

    func testDelete_NonExistentItem_ThrowsNotFound() async {
        do {
            try await deleteUseCase.execute(id: UUID())
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - ToggleAllItemsPaidInListUseCase

@MainActor
final class ToggleAllItemsPaidUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var toggleUseCase: ToggleAllItemsPaidInListUseCase!
    private var fetchUseCase: FetchItemsUseCase!
    private var group: SDGroup!
    private var itemList: SDItemList!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        let repo = swiftData.makeItemRepository()
        toggleUseCase = DefaultToggleAllItemsPaidInListUseCase(itemRepository: repo)
        fetchUseCase = DefaultFetchItemsUseCase(itemRepository: repo)
        group = try swiftData.insertGroup()
        itemList = try swiftData.insertItemList(group: group)
    }

    override func tearDown() {
        toggleUseCase = nil
        fetchUseCase = nil
        itemList = nil
        group = nil
        swiftData = nil
    }

    func testMarkAllPaid_AllItemsBecomePaid() async throws {
        try swiftData.insertItem(isPaid: false, itemList: itemList)
        try swiftData.insertItem(isPaid: false, itemList: itemList)

        try await toggleUseCase.execute(itemListId: itemList.id, isPaid: true)

        let items = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertTrue(items.allSatisfy { $0.isPaid })
    }

    func testMarkAllUnpaid_AllItemsBecomeUnpaid() async throws {
        try swiftData.insertItem(isPaid: true, itemList: itemList)
        try swiftData.insertItem(isPaid: true, itemList: itemList)

        try await toggleUseCase.execute(itemListId: itemList.id, isPaid: false)

        let items = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertTrue(items.allSatisfy { !$0.isPaid })
    }

    func testMarkAllPaid_MixedInitialState_AllBecomePaid() async throws {
        try swiftData.insertItem(isPaid: true, itemList: itemList)
        try swiftData.insertItem(isPaid: false, itemList: itemList)
        try swiftData.insertItem(isPaid: false, itemList: itemList)

        try await toggleUseCase.execute(itemListId: itemList.id, isPaid: true)

        let items = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertTrue(items.allSatisfy { $0.isPaid })
    }

    func testToggle_EmptyList_NoError() async throws {
        try await toggleUseCase.execute(itemListId: itemList.id, isPaid: true)
        // no items, no crash
        let items = try await fetchUseCase.execute(forItemListId: itemList.id)
        XCTAssertTrue(items.isEmpty)
    }

    func testToggle_OnlyAffectsTargetList() async throws {
        let otherList = try swiftData.insertItemList(description: "Otra", group: group)
        try swiftData.insertItem(isPaid: false, itemList: itemList)
        try swiftData.insertItem(isPaid: false, itemList: otherList)

        try await toggleUseCase.execute(itemListId: itemList.id, isPaid: true)

        let targetItems = try await fetchUseCase.execute(forItemListId: itemList.id)
        let otherItems = try await fetchUseCase.execute(forItemListId: otherList.id)

        XCTAssertTrue(targetItems.allSatisfy { $0.isPaid })
        XCTAssertTrue(otherItems.allSatisfy { !$0.isPaid })
    }
}
