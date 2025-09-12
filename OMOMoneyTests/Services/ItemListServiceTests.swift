import XCTest
import CoreData
@testable import OMOMoney

final class itemListServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var itemListService: itemListService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        itemListService = itemListService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create itemList Tests
    
    func testCreateitemList_Success() async throws {
        // Given
        let itemListDescription = "Test itemList"
        let itemListDate = Date()
        let testGroup = testEntityFactory.createGroup()
        let testCategory = testEntityFactory.createCategory(group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let createditemList = try await itemListService.createitemList(
            description: itemListDescription,
            date: itemListDate,
            categoryId: testCategory.id ?? UUID(),
            groupId: testGroup.id ?? UUID()
        )
        
        // Then
        XCTAssertNotNil(createditemList)
        XCTAssertEqual(createditemList.itemListDescription, itemListDescription)
        XCTAssertEqual(createditemList.date, itemListDate)
        XCTAssertEqual(createditemList.category, testCategory)
        XCTAssertEqual(createditemList.group, testGroup)
        XCTAssertNotNil(createditemList.id)
        XCTAssertNotNil(createditemList.createdAt)
        
        // Verify itemList was saved to Core Data
        let saveditemList = try await itemListService.fetchitemList(by: createditemList.id!)
        XCTAssertNotNil(saveditemList)
        XCTAssertEqual(saveditemList?.itemListDescription, itemListDescription)
    }
    
    func testCreateitemList_WithoutCategory() async throws {
        // Given
        let itemListDescription = "itemList without category"
        let itemListDate = Date()
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let createditemList = try await itemListService.createitemList(
            description: itemListDescription,
            date: itemListDate,
            categoryId: UUID(), // Generate a new UUID for testing
            groupId: testGroup.id ?? UUID()
        )
        
        // Then
        XCTAssertNotNil(createditemList)
        XCTAssertEqual(createditemList.itemListDescription, itemListDescription)
        XCTAssertNil(createditemList.category)
        XCTAssertEqual(createditemList.group, testGroup)
    }
    
    // MARK: - Fetch itemList Tests
    
    func testfetchItemLists_Empty() async throws {
        // When
        let itemLists = try await itemListService.fetchitemLists()
        
        // Then
        XCTAssertTrue(itemLists.isEmpty)
    }
    
    func testFetchItemLists_WithData() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createitemLists(count: 3, group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let fetcheditemLists = try await itemListService.fetchitemLists()
        
        // Then
        XCTAssertEqual(fetcheditemLists.count, 3)
        XCTAssertTrue(fetcheditemLists.allSatisfy { $0.itemListDescription?.contains("itemList") == true })
    }
    
    func testFetchitemList_ById() async throws {
        // Given
        let testitemList = testEntityFactory.createitemList()
        try mockCoreDataStack.save()
        
        // When
        let fetcheditemList = try await itemListService.fetchitemList(by: testitemList.id!)
        
        // Then
        XCTAssertNotNil(fetcheditemList)
        XCTAssertEqual(fetcheditemList?.id, testitemList.id)
        XCTAssertEqual(fetcheditemList?.itemListDescription, testitemList.itemListDescription)
    }
    
    func testFetchitemList_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetcheditemList = try await itemListService.fetchitemList(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetcheditemList)
    }
    
    func testGetitemLists_ForGroup() async throws {
        // Given
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        _ = testEntityFactory.createitemLists(count: 2, group: group1)
        _ = testEntityFactory.createitemLists(count: 3, group: group2)
        try mockCoreDataStack.save()
        
        // When
        let group1itemLists = try await itemListService.getitemLists(for: group1)
        let group2itemLists = try await itemListService.getitemLists(for: group2)
        
        // Then
        XCTAssertEqual(group1itemLists.count, 2)
        XCTAssertEqual(group2itemLists.count, 3)
        XCTAssertTrue(group1itemLists.allSatisfy { $0.group == group1 })
        XCTAssertTrue(group2itemLists.allSatisfy { $0.group == group2 })
    }
    
    func testGetitemLists_ForCategory() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let category1 = testEntityFactory.createCategory(name: "Category 1", group: testGroup)
        let category2 = testEntityFactory.createCategory(name: "Category 2", group: testGroup)
        _ = testEntityFactory.createitemLists(count: 2, category: category1, group: testGroup)
        _ = testEntityFactory.createitemLists(count: 3, category: category2, group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let category1itemLists = try await itemListService.getitemLists(for: category1)
        let category2itemLists = try await itemListService.getitemLists(for: category2)
        
        // Then
        XCTAssertEqual(category1itemLists.count, 2)
        XCTAssertEqual(category2itemLists.count, 3)
        XCTAssertTrue(category1itemLists.allSatisfy { $0.category == category1 })
        XCTAssertTrue(category2itemLists.allSatisfy { $0.category == category2 })
    }
    
    // MARK: - Update itemList Tests
    
    func testUpdateitemList_Success() async throws {
        // Given
        let testitemList = testEntityFactory.createitemList()
        try mockCoreDataStack.save()
        
        let newDescription = "Updated itemList"
        let newDate = Date().addingTimeInterval(86400) // Tomorrow
        
        // When
        try await itemListService.updateitemList(testitemList, description: newDescription, date: newDate, categoryId: testitemList.category?.id ?? UUID())
        
        // Then
        XCTAssertEqual(testitemList.itemListDescription, newDescription)
        XCTAssertEqual(testitemList.date, newDate)
        XCTAssertNotNil(testitemList.lastModifiedAt)
        
        // Verify changes were saved
        let updateditemList = try await itemListService.fetchitemList(by: testitemList.id!)
        XCTAssertEqual(updateditemList?.itemListDescription, newDescription)
        XCTAssertEqual(updateditemList?.date, newDate)
    }
    
    // MARK: - Delete itemList Tests
    
    func testDeleteitemList_Success() async throws {
        // Given
        let testitemList = testEntityFactory.createitemList()
        try mockCoreDataStack.save()
        
        // When
        try await itemListService.deleteitemList(testitemList)
        
        // Then
        let deleteditemList = try await itemListService.fetchitemList(by: testitemList.id!)
        XCTAssertNil(deleteditemList)
    }
    
    // MARK: - Caching Tests
    
    func testfetchItemLists_Caching() async throws {
        // Given
        _ = testEntityFactory.createitemLists(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemListService.fetchitemLists()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemListService.fetchitemLists()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetitemListsForGroup_Caching() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createitemLists(count: 3, group: testGroup)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemListService.getitemLists(for: testGroup)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemListService.getitemLists(for: testGroup)
        
        // Then
        XCTAssertEqual(firstFetch.count, 3)
        XCTAssertEqual(secondFetch.count, 3) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetitemListsForCategory_Caching() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        _ = testEntityFactory.createitemLists(count: 2, category: testCategory)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await itemListService.getitemLists(for: testCategory)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await itemListService.getitemLists(for: testCategory)
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateitemList_InvalidatesCache() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createitemLists(count: 2, group: testGroup)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemListService.getitemLists(for: testGroup)
        
        // When
        _ = try await itemListService.createitemList(
            description: "New itemList",
            date: Date(),
            categoryId: UUID(), // Generate a new UUID for testing
            groupId: testGroup.id ?? UUID()
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let allitemLists = try await itemListService.getitemLists(for: testGroup)
        XCTAssertEqual(allitemLists.count, 3) // Should include the new itemList
        XCTAssertTrue(allitemLists.contains { $0.itemListDescription == "New itemList" })
    }
    
    func testUpdateitemList_InvalidatesCache() async throws {
        // Given
        let testitemList = testEntityFactory.createitemList(description: "Original itemList")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemListService.fetchitemLists()
        
        // When
        try await itemListService.updateitemList(testitemList, description: "Updated itemList", categoryId: testitemList.category?.id ?? UUID())
        
        // Then - Cache should be invalidated
        let updateditemList = try await itemListService.fetchitemList(by: testitemList.id!)
        XCTAssertEqual(updateditemList?.itemListDescription, "Updated itemList")
    }
    
    func testDeleteitemList_InvalidatesCache() async throws {
        // Given
        let testitemList = testEntityFactory.createitemList()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await itemListService.fetchitemLists()
        
        // When
        try await itemListService.deleteitemList(testitemList)
        
        // Then - Cache should be invalidated
        let allitemLists = try await itemListService.fetchitemLists()
        XCTAssertEqual(allitemLists.count, 0) // Should reflect deletion
    }
}
