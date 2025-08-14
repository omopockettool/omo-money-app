import XCTest
import CoreData
@testable import OMOMoney

final class EntryServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var entryService: EntryService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        entryService = EntryService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create Entry Tests
    
    func testCreateEntry_Success() async throws {
        // Given
        let entryDescription = "Test Entry"
        let entryDate = Date()
        let testGroup = testEntityFactory.createGroup()
        let testCategory = testEntityFactory.createCategory(group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let createdEntry = try await entryService.createEntry(
            description: entryDescription,
            date: entryDate,
            category: testCategory,
            group: testGroup
        )
        
        // Then
        XCTAssertNotNil(createdEntry)
        XCTAssertEqual(createdEntry.entryDescription, entryDescription)
        XCTAssertEqual(createdEntry.date, entryDate)
        XCTAssertEqual(createdEntry.category, testCategory)
        XCTAssertEqual(createdEntry.group, testGroup)
        XCTAssertNotNil(createdEntry.id)
        XCTAssertNotNil(createdEntry.createdAt)
        
        // Verify entry was saved to Core Data
        let savedEntry = try await entryService.fetchEntry(by: createdEntry.id!)
        XCTAssertNotNil(savedEntry)
        XCTAssertEqual(savedEntry?.entryDescription, entryDescription)
    }
    
    func testCreateEntry_WithoutCategory() async throws {
        // Given
        let entryDescription = "Entry without category"
        let entryDate = Date()
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let createdEntry = try await entryService.createEntry(
            description: entryDescription,
            date: entryDate,
            category: nil,
            group: testGroup
        )
        
        // Then
        XCTAssertNotNil(createdEntry)
        XCTAssertEqual(createdEntry.entryDescription, entryDescription)
        XCTAssertNil(createdEntry.category)
        XCTAssertEqual(createdEntry.group, testGroup)
    }
    
    // MARK: - Fetch Entry Tests
    
    func testFetchEntries_Empty() async throws {
        // When
        let entries = try await entryService.fetchEntries()
        
        // Then
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testFetchEntries_WithData() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let testEntries = testEntityFactory.createEntries(count: 3, group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let fetchedEntries = try await entryService.fetchEntries()
        
        // Then
        XCTAssertEqual(fetchedEntries.count, 3)
        XCTAssertTrue(fetchedEntries.allSatisfy { $0.entryDescription?.contains("Entry") == true })
    }
    
    func testFetchEntry_ById() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        // When
        let fetchedEntry = try await entryService.fetchEntry(by: testEntry.id!)
        
        // Then
        XCTAssertNotNil(fetchedEntry)
        XCTAssertEqual(fetchedEntry?.id, testEntry.id)
        XCTAssertEqual(fetchedEntry?.entryDescription, testEntry.entryDescription)
    }
    
    func testFetchEntry_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedEntry = try await entryService.fetchEntry(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedEntry)
    }
    
    func testGetEntries_ForGroup() async throws {
        // Given
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        let entries1 = testEntityFactory.createEntries(count: 2, group: group1)
        let entries2 = testEntityFactory.createEntries(count: 3, group: group2)
        try mockCoreDataStack.save()
        
        // When
        let group1Entries = try await entryService.getEntries(for: group1)
        let group2Entries = try await entryService.getEntries(for: group2)
        
        // Then
        XCTAssertEqual(group1Entries.count, 2)
        XCTAssertEqual(group2Entries.count, 3)
        XCTAssertTrue(group1Entries.allSatisfy { $0.group == group1 })
        XCTAssertTrue(group2Entries.allSatisfy { $0.group == group2 })
    }
    
    func testGetEntries_ForCategory() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let category1 = testEntityFactory.createCategory(name: "Category 1", group: testGroup)
        let category2 = testEntityFactory.createCategory(name: "Category 2", group: testGroup)
        let entries1 = testEntityFactory.createEntries(count: 2, category: category1, group: testGroup)
        let entries2 = testEntityFactory.createEntries(count: 3, category: category2, group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let category1Entries = try await entryService.getEntries(for: category1)
        let category2Entries = try await entryService.getEntries(for: category2)
        
        // Then
        XCTAssertEqual(category1Entries.count, 2)
        XCTAssertEqual(category2Entries.count, 3)
        XCTAssertTrue(category1Entries.allSatisfy { $0.category == category1 })
        XCTAssertTrue(category2Entries.allSatisfy { $0.category == category2 })
    }
    
    // MARK: - Update Entry Tests
    
    func testUpdateEntry_Success() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        let newDescription = "Updated Entry"
        let newDate = Date().addingTimeInterval(86400) // Tomorrow
        
        // When
        try await entryService.updateEntry(testEntry, description: newDescription, date: newDate)
        
        // Then
        XCTAssertEqual(testEntry.entryDescription, newDescription)
        XCTAssertEqual(testEntry.date, newDate)
        XCTAssertNotNil(testEntry.lastModifiedAt)
        
        // Verify changes were saved
        let updatedEntry = try await entryService.fetchEntry(by: testEntry.id!)
        XCTAssertEqual(updatedEntry?.entryDescription, newDescription)
        XCTAssertEqual(updatedEntry?.date, newDate)
    }
    
    // MARK: - Delete Entry Tests
    
    func testDeleteEntry_Success() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        // When
        try await entryService.deleteEntry(testEntry)
        
        // Then
        let deletedEntry = try await entryService.fetchEntry(by: testEntry.id!)
        XCTAssertNil(deletedEntry)
    }
    
    // MARK: - Caching Tests
    
    func testFetchEntries_Caching() async throws {
        // Given
        let testEntries = testEntityFactory.createEntries(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await entryService.fetchEntries()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await entryService.fetchEntries()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetEntriesForGroup_Caching() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let testEntries = testEntityFactory.createEntries(count: 3, group: testGroup)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await entryService.getEntries(for: testGroup)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await entryService.getEntries(for: testGroup)
        
        // Then
        XCTAssertEqual(firstFetch.count, 3)
        XCTAssertEqual(secondFetch.count, 3) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetEntriesForCategory_Caching() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        let testEntries = testEntityFactory.createEntries(count: 2, category: testCategory)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await entryService.getEntries(for: testCategory)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await entryService.getEntries(for: testCategory)
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateEntry_InvalidatesCache() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        let testEntries = testEntityFactory.createEntries(count: 2, group: testGroup)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await entryService.getEntries(for: testGroup)
        
        // When
        _ = try await entryService.createEntry(
            description: "New Entry",
            date: Date(),
            category: nil,
            group: testGroup
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let allEntries = try await entryService.getEntries(for: testGroup)
        XCTAssertEqual(allEntries.count, 3) // Should include the new entry
        XCTAssertTrue(allEntries.contains { $0.entryDescription == "New Entry" })
    }
    
    func testUpdateEntry_InvalidatesCache() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry(description: "Original Entry")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await entryService.fetchEntries()
        
        // When
        try await entryService.updateEntry(testEntry, description: "Updated Entry")
        
        // Then - Cache should be invalidated
        let updatedEntry = try await entryService.fetchEntry(by: testEntry.id!)
        XCTAssertEqual(updatedEntry?.entryDescription, "Updated Entry")
    }
    
    func testDeleteEntry_InvalidatesCache() async throws {
        // Given
        let testEntry = testEntityFactory.createEntry()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await entryService.fetchEntries()
        
        // When
        try await entryService.deleteEntry(testEntry)
        
        // Then - Cache should be invalidated
        let allEntries = try await entryService.fetchEntries()
        XCTAssertEqual(allEntries.count, 0) // Should reflect deletion
    }
}
