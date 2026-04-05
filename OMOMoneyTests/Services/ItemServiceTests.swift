import XCTest
import CoreData
@testable import OMOMoney

final class ItemServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var itemService: ItemService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        itemService = ItemService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create Item Tests
    
    func testCreateItem_Success() async throws {
        // Given
        let itemDescription = "Test Item"
        let itemAmount = NSDecimalNumber(value: 25.50)
        let itemQuantity: Int32 = 2
        let testItemList = testEntityFactory.createItemList()
        try mockCoreDataStack.save()
        
        // When
        let createdItem = try await itemService.createItem(
            description: itemDescription,
            amount: itemAmount,
            quantity: itemQuantity,
            itemList: testItemList
        )
        
        // Then
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem.itemDescription, itemDescription)
        XCTAssertEqual(createdItem.amount, itemAmount)
        XCTAssertEqual(createdItem.quantity, itemQuantity)
        XCTAssertEqual(createdItem.itemList, testItemList)
        XCTAssertNotNil(createdItem.id)
        XCTAssertNotNil(createdItem.createdAt)
        
        // Verify item was saved to Core Data
        let savedItem = try await itemService.fetchItem(by: createdItem.id!)
        XCTAssertNotNil(savedItem)
        XCTAssertEqual(savedItem?.itemDescription, itemDescription)
    }
    
    func testCreateItem_WithoutItemList() async throws {
        // Given
        let itemDescription = "Item without itemList"
        let itemAmount = NSDecimalNumber(value: 10.00)
        let itemQuantity: Int32 = 1
        let testItemList = testEntityFactory.createItemList()
        
        // When
        let createdItem = try await itemService.createItem(
            description: itemDescription,
            amount: itemAmount,
            quantity: itemQuantity,
            itemList: testItemList
        )
        
        // Then
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem.itemDescription, itemDescription)
        XCTAssertEqual(createdItem.amount, itemAmount)
        XCTAssertEqual(createdItem.quantity, itemQuantity)
        XCTAssertEqual(createdItem.itemList, testItemList)
    }
    
    // MARK: - Fetch Item Tests
    
    func testFetchItem_ById() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()
        
        // When
        let fetchedItem = try await itemService.fetchItem(by: testItem.id!)
        
        // Then
        XCTAssertNotNil(fetchedItem)
        XCTAssertEqual(fetchedItem?.id, testItem.id)
        XCTAssertEqual(fetchedItem?.itemDescription, testItem.itemDescription)
    }
    
    func testFetchItem_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedItem = try await itemService.fetchItem(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedItem)
    }
    
    func testGetItems_ForItemList() async throws {
        // Given
        let itemList1 = testEntityFactory.createItemList(description: "ItemList 1")
        let itemList2 = testEntityFactory.createItemList(description: "ItemList 2")
        _ = testEntityFactory.createItems(count: 2, itemList: itemList1)
        _ = testEntityFactory.createItems(count: 3, itemList: itemList2)
        try mockCoreDataStack.save()
        
        // When
        let itemList1Items = try await itemService.getItems(for: itemList1)
        let itemList2Items = try await itemService.getItems(for: itemList2)
        
        // Then
        XCTAssertEqual(itemList1Items.count, 2)
        XCTAssertEqual(itemList2Items.count, 3)
        XCTAssertTrue(itemList1Items.allSatisfy { $0.itemList == itemList1 })
        XCTAssertTrue(itemList2Items.allSatisfy { $0.itemList == itemList2 })
    }
    
    // MARK: - Update Item Tests
    
    func testUpdateItem_Success() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()
        
        let newDescription = "Updated Item"
        let newAmount = NSDecimalNumber(value: 15.75)
        let newQuantity: Int32 = 3
        let itemId = testItem.id!

        // When
        try await itemService.updateItem(itemId: itemId, description: newDescription, amount: newAmount, quantity: newQuantity)

        // Then - Fetch the item to verify updates
        let updatedItem = try await itemService.fetchItem(by: itemId)
        XCTAssertNotNil(updatedItem)
        XCTAssertEqual(updatedItem?.itemDescription, newDescription)
        XCTAssertEqual(updatedItem?.amount, newAmount)
        XCTAssertEqual(updatedItem?.quantity, newQuantity)
    }
    
    func testUpdateItem_PartialUpdate() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()

        let originalDescription = testItem.itemDescription
        let newAmount = NSDecimalNumber(value: 20.00)
        let itemId = testItem.id!

        // When
        try await itemService.updateItem(itemId: itemId, description: nil, amount: newAmount, quantity: nil)

        // Then - Fetch the item to verify partial update
        let updatedItem = try await itemService.fetchItem(by: itemId)
        XCTAssertNotNil(updatedItem)
        XCTAssertEqual(updatedItem?.itemDescription, originalDescription) // Description unchanged
        XCTAssertEqual(updatedItem?.amount, newAmount) // Amount updated
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteItem_Success() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()
        
        // When
        try await itemService.deleteItem(testItem)
        
        // Then
        let deletedItem = try await itemService.fetchItem(by: testItem.id!)
        XCTAssertNil(deletedItem)
    }
    
    // MARK: - Calculation Tests
    
    func testCalculateTotalAmount_ForItemList() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        _ = testEntityFactory.createItem(amount: NSDecimalNumber(value: 10.00), quantity: 2, itemList: testItemList)
        _ = testEntityFactory.createItem(amount: NSDecimalNumber(value: 15.50), quantity: 1, itemList: testItemList)
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testItemList)
        
        // Then
        let expectedTotal = NSDecimalNumber(value: 10.00).multiplying(by: NSDecimalNumber(value: 2))
            .adding(NSDecimalNumber(value: 15.50).multiplying(by: NSDecimalNumber(value: 1)))
        XCTAssertEqual(totalAmount, expectedTotal)
    }
    
    func testCalculateTotalAmount_ForItemListWithNoItems() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testItemList)
        
        // Then
        XCTAssertEqual(totalAmount, NSDecimalNumber.zero)
    }
    
    func testCalculateTotalAmount_ForGroup() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let itemList1 = testEntityFactory.createItemList(group: testGroup)
        let itemList2 = testEntityFactory.createItemList(group: testGroup)
        _ = testEntityFactory.createItem(amount: NSDecimalNumber(value: 20.00), quantity: 1, itemList: itemList1)
        _ = testEntityFactory.createItem(amount: NSDecimalNumber(value: 30.00), quantity: 2, itemList: itemList2)
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testGroup)
        
        // Then
        let expectedTotal = NSDecimalNumber(value: 20.00).multiplying(by: NSDecimalNumber(value: 1))
            .adding(NSDecimalNumber(value: 30.00).multiplying(by: NSDecimalNumber(value: 2)))
        XCTAssertEqual(totalAmount, expectedTotal)
    }
    
    func testCalculateTotalAmount_ForGroupWithNoItemLists() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testGroup)
        
        // Then
        XCTAssertEqual(totalAmount, NSDecimalNumber.zero)
    }
    
    // MARK: - Caching Tests
    

    
    func testGetItemsForItemList_Caching() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        _ = testEntityFactory.createItems(count: 3, itemList: testItemList)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemService.getItems(for: testItemList)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemService.getItems(for: testItemList)
        
        // Then
        XCTAssertEqual(firstFetch.count, 3)
        XCTAssertEqual(secondFetch.count, 3) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testCalculateTotalAmount_Caching() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        _ = testEntityFactory.createItems(count: 2, itemList: testItemList)
        try mockCoreDataStack.save()
        
        // When - First calculation (should cache)
        let firstCalculation = try await itemService.calculateTotalAmount(for: testItemList)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second calculation (should use cache)
        let secondCalculation = try await itemService.calculateTotalAmount(for: testItemList)
        
        // Then
        XCTAssertEqual(firstCalculation, secondCalculation) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateItem_InvalidatesCache() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        _ = testEntityFactory.createItems(count: 2, itemList: testItemList)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemService.getItems(for: testItemList)
        _ = try await itemService.calculateTotalAmount(for: testItemList)
        
        // When
        _ = try await itemService.createItem(
            description: "New Item",
            amount: NSDecimalNumber(value: 25.00),
            quantity: 1,
            itemList: testItemList
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let allItems = try await itemService.getItems(for: testItemList)
        XCTAssertEqual(allItems.count, 3) // Should include the new item
        XCTAssertTrue(allItems.contains { $0.itemDescription == "New Item" })
    }
    
    func testUpdateItem_InvalidatesCache() async throws {
        // Given
        let testItem = testEntityFactory.createItem(description: "Original Item")
        try mockCoreDataStack.save()
        let itemId = testItem.id!

        // When
        try await itemService.updateItem(itemId: itemId, description: "Updated Item", amount: nil, quantity: nil)

        // Then - Cache should be invalidated
        let updatedItem = try await itemService.fetchItem(by: itemId)
        XCTAssertEqual(updatedItem?.itemDescription, "Updated Item")
    }
    
    func testDeleteItem_InvalidatesCache() async throws {
        // Given
        let testItemList = testEntityFactory.createItemList()
        let testItem = testEntityFactory.createItem(itemList: testItemList)
        try mockCoreDataStack.save()
        
        // When
        try await itemService.deleteItem(testItem)
        
        // Then - Verify deletion by checking items in the itemList
        let remainingItems = try await itemService.getItems(for: testItemList)
        XCTAssertEqual(remainingItems.count, 0) // Should reflect deletion
    }
}
