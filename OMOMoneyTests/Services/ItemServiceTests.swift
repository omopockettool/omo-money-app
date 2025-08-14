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
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        // When
        let createdItem = try await itemService.createItem(
            description: itemDescription,
            amount: itemAmount,
            quantity: itemQuantity,
            entry: testEntry
        )
        
        // Then
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem.itemDescription, itemDescription)
        XCTAssertEqual(createdItem.amount, itemAmount)
        XCTAssertEqual(createdItem.quantity, itemQuantity)
        XCTAssertEqual(createdItem.entry, testEntry)
        XCTAssertNotNil(createdItem.id)
        XCTAssertNotNil(createdItem.createdAt)
        
        // Verify item was saved to Core Data
        let savedItem = try await itemService.fetchItem(by: createdItem.id!)
        XCTAssertNotNil(savedItem)
        XCTAssertEqual(savedItem?.itemDescription, itemDescription)
    }
    
    func testCreateItem_WithoutEntry() async throws {
        // Given
        let itemDescription = "Item without entry"
        let itemAmount = NSDecimalNumber(value: 10.00)
        let itemQuantity: Int32 = 1
        
        // When
        let createdItem = try await itemService.createItem(
            description: itemDescription,
            amount: itemAmount,
            quantity: itemQuantity,
            entry: nil
        )
        
        // Then
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem.itemDescription, itemDescription)
        XCTAssertEqual(createdItem.amount, itemAmount)
        XCTAssertEqual(createdItem.quantity, itemQuantity)
        XCTAssertNil(createdItem.entry)
    }
    
    // MARK: - Fetch Item Tests
    
    func testFetchItems_Empty() async throws {
        // When
        let items = try await itemService.fetchItems()
        
        // Then
        XCTAssertTrue(items.isEmpty)
    }
    
    func testFetchItems_WithData() async throws {
        // Given
        let testItems = testEntityFactory.createItems(count: 3)
        try mockCoreDataStack.save()
        
        // When
        let fetchedItems = try await itemService.fetchItems()
        
        // Then
        XCTAssertEqual(fetchedItems.count, 3)
        XCTAssertTrue(fetchedItems.allSatisfy { $0.itemDescription?.contains("Item") == true })
    }
    
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
    
    func testGetItems_ForEntry() async throws {
        // Given
        let entry1 = testEntityFactory.createEntry(description: "Entry 1")
        let entry2 = testEntityFactory.createEntry(description: "Entry 2")
        let items1 = testEntityFactory.createItems(count: 2, entry: entry1)
        let items2 = testEntityFactory.createItems(count: 3, entry: entry2)
        try mockCoreDataStack.save()
        
        // When
        let entry1Items = try await itemService.getItems(for: entry1)
        let entry2Items = try await itemService.getItems(for: entry2)
        
        // Then
        XCTAssertEqual(entry1Items.count, 2)
        XCTAssertEqual(entry2Items.count, 3)
        XCTAssertTrue(entry1Items.allSatisfy { $0.entry == entry1 })
        XCTAssertTrue(entry2Items.allSatisfy { $0.entry == entry2 })
    }
    
    // MARK: - Update Item Tests
    
    func testUpdateItem_Success() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()
        
        let newDescription = "Updated Item"
        let newAmount = NSDecimalNumber(value: 15.75)
        let newQuantity: Int32 = 3
        
        // When
        try await itemService.updateItem(testItem, description: newDescription, amount: newAmount, quantity: newQuantity)
        
        // Then
        XCTAssertEqual(testItem.itemDescription, newDescription)
        XCTAssertEqual(testItem.amount, newAmount)
        XCTAssertEqual(testItem.quantity, newQuantity)
        XCTAssertNotNil(testItem.lastModifiedAt)
        
        // Verify changes were saved
        let updatedItem = try await itemService.fetchItem(by: testItem.id!)
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
        
        // When
        try await itemService.updateItem(testItem, description: nil, amount: newAmount, quantity: nil)
        
        // Then
        XCTAssertEqual(testItem.itemDescription, originalDescription) // Description unchanged
        XCTAssertEqual(testItem.amount, newAmount) // Amount updated
        XCTAssertNotNil(testItem.lastModifiedAt)
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
    
    func testCalculateTotalAmount_ForEntry() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        let item1 = testEntityFactory.createItem(amount: NSDecimalNumber(value: 10.00), quantity: 2, entry: testEntry)
        let item2 = testEntityFactory.createItem(amount: NSDecimalNumber(value: 15.50), quantity: 1, entry: testEntry)
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testEntry)
        
        // Then
        let expectedTotal = NSDecimalNumber(value: 10.00).multiplying(by: NSDecimalNumber(value: 2))
            .adding(NSDecimalNumber(value: 15.50).multiplying(by: NSDecimalNumber(value: 1)))
        XCTAssertEqual(totalAmount, expectedTotal)
    }
    
    func testCalculateTotalAmount_ForEntryWithNoItems() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testEntry)
        
        // Then
        XCTAssertEqual(totalAmount, NSDecimalNumber.zero)
    }
    
    func testCalculateTotalAmount_ForGroup() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let entry1 = testEntityFactory.createEntry(group: testGroup)
        let entry2 = testEntityFactory.createEntry(group: testGroup)
        let item1 = testEntityFactory.createItem(amount: NSDecimalNumber(value: 20.00), quantity: 1, entry: entry1)
        let item2 = testEntityFactory.createItem(amount: NSDecimalNumber(value: 30.00), quantity: 2, entry: entry2)
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testGroup)
        
        // Then
        let expectedTotal = NSDecimalNumber(value: 20.00).multiplying(by: NSDecimalNumber(value: 1))
            .adding(NSDecimalNumber(value: 30.00).multiplying(by: NSDecimalNumber(value: 2)))
        XCTAssertEqual(totalAmount, expectedTotal)
    }
    
    func testCalculateTotalAmount_ForGroupWithNoEntries() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let totalAmount = try await itemService.calculateTotalAmount(for: testGroup)
        
        // Then
        XCTAssertEqual(totalAmount, NSDecimalNumber.zero)
    }
    
    // MARK: - Caching Tests
    
    func testFetchItems_Caching() async throws {
        // Given
        let testItems = testEntityFactory.createItems(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemService.fetchItems()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemService.fetchItems()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetItemsForEntry_Caching() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        let testItems = testEntityFactory.createItems(count: 3, entry: testEntry)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemService.getItems(for: testEntry)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemService.getItems(for: testEntry)
        
        // Then
        XCTAssertEqual(firstFetch.count, 3)
        XCTAssertEqual(secondFetch.count, 3) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testCalculateTotalAmount_Caching() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        let testItems = testEntityFactory.createItems(count: 2, entry: testEntry)
        try mockCoreDataStack.save()
        
        // When - First calculation (should cache)
        let firstCalculation = try await itemService.calculateTotalAmount(for: testEntry)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second calculation (should use cache)
        let secondCalculation = try await itemService.calculateTotalAmount(for: testEntry)
        
        // Then
        XCTAssertEqual(firstCalculation, secondCalculation) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateItem_InvalidatesCache() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        let testItems = testEntityFactory.createItems(count: 2, entry: testEntry)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemService.getItems(for: testEntry)
        _ = try await itemService.calculateTotalAmount(for: testEntry)
        
        // When
        _ = try await itemService.createItem(
            description: "New Item",
            amount: NSDecimalNumber(value: 25.00),
            quantity: 1,
            entry: testEntry
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let allItems = try await itemService.getItems(for: testEntry)
        XCTAssertEqual(allItems.count, 3) // Should include the new item
        XCTAssertTrue(allItems.contains { $0.itemDescription == "New Item" })
    }
    
    func testUpdateItem_InvalidatesCache() async throws {
        // Given
        let testItem = testEntityFactory.createItem(description: "Original Item")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemService.fetchItems()
        
        // When
        try await itemService.updateItem(testItem, description: "Updated Item", amount: nil, quantity: nil)
        
        // Then - Cache should be invalidated
        let updatedItem = try await itemService.fetchItem(by: testItem.id!)
        XCTAssertEqual(updatedItem?.itemDescription, "Updated Item")
    }
    
    func testDeleteItem_InvalidatesCache() async throws {
        // Given
        let testItem = testEntityFactory.createItem()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemService.fetchItems()
        
        // When
        try await itemService.deleteItem(testItem)
        
        // Then - Cache should be invalidated
        let allItems = try await itemService.fetchItems()
        XCTAssertEqual(allItems.count, 0) // Should reflect deletion
    }
}
