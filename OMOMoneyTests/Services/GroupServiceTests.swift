import XCTest
import CoreData
@testable import OMOMoney

final class GroupServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var groupService: GroupService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        groupService = GroupService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create Group Tests
    
    func testCreateGroup_Success() async throws {
        // Given
        let groupName = "Test Group"
        let groupCurrency = "USD"
        
        // When
        let createdGroup = try await groupService.createGroup(name: groupName, currency: groupCurrency)
        
        // Then
        XCTAssertNotNil(createdGroup)
        XCTAssertEqual(createdGroup.name, groupName)
        XCTAssertEqual(createdGroup.currency, groupCurrency)
        XCTAssertNotNil(createdGroup.id)
        XCTAssertNotNil(createdGroup.createdAt)
        
        // Verify group was saved to Core Data
        let savedGroup = try await groupService.fetchGroup(by: createdGroup.id!)
        XCTAssertNotNil(savedGroup)
        XCTAssertEqual(savedGroup?.name, groupName)
    }
    
    // MARK: - Fetch Group Tests
    
    func testFetchGroups_Empty() async throws {
        // When
        let groups = try await groupService.fetchGroups()
        
        // Then
        XCTAssertTrue(groups.isEmpty)
    }
    
    func testFetchGroups_WithData() async throws {
        // Given
        let testGroups = testEntityFactory.createGroups(count: 3)
        try mockCoreDataStack.save()
        
        // When
        let fetchedGroups = try await groupService.fetchGroups()
        
        // Then
        XCTAssertEqual(fetchedGroups.count, 3)
        XCTAssertTrue(fetchedGroups.allSatisfy { $0.name?.contains("Group") == true })
    }
    
    func testFetchGroup_ById() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let fetchedGroup = try await groupService.fetchGroup(by: testGroup.id!)
        
        // Then
        XCTAssertNotNil(fetchedGroup)
        XCTAssertEqual(fetchedGroup?.id, testGroup.id)
        XCTAssertEqual(fetchedGroup?.name, testGroup.name)
    }
    
    func testFetchGroup_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedGroup = try await groupService.fetchGroup(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedGroup)
    }
    
    // MARK: - Update Group Tests
    
    func testUpdateGroup_Success() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        let newName = "Updated Group"
        let newCurrency = "EUR"
        
        // When
        try await groupService.updateGroup(testGroup, name: newName, currency: newCurrency)
        
        // Then
        XCTAssertEqual(testGroup.name, newName)
        XCTAssertEqual(testGroup.currency, newCurrency)
        XCTAssertNotNil(testGroup.lastModifiedAt)
        
        // Verify changes were saved
        let updatedGroup = try await groupService.fetchGroup(by: testGroup.id!)
        XCTAssertEqual(updatedGroup?.name, newName)
        XCTAssertEqual(updatedGroup?.currency, newCurrency)
    }
    
    // MARK: - Delete Group Tests
    
    func testDeleteGroup_Success() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        try await groupService.deleteGroup(testGroup)
        
        // Then
        let deletedGroup = try await groupService.fetchGroup(by: testGroup.id!)
        XCTAssertNil(deletedGroup)
    }
    
    // MARK: - Validation Tests
    
    func testGroupExists_True() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup(name: "Unique Group")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await groupService.groupExists(withName: "Unique Group")
        
        // Then
        XCTAssertTrue(exists)
    }
    
    func testGroupExists_False() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup(name: "Existing Group")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await groupService.groupExists(withName: "Non Existent Group")
        
        // Then
        XCTAssertFalse(exists)
    }
    
    // MARK: - Count Tests
    
    func testGetGroupsCount_Empty() async throws {
        // When
        let count = try await groupService.getGroupsCount()
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testGetGroupsCount_WithData() async throws {
        // Given
        let testGroups = testEntityFactory.createGroups(count: 4)
        try mockCoreDataStack.save()
        
        // When
        let count = try await groupService.getGroupsCount()
        
        // Then
        XCTAssertEqual(count, 4)
    }
    
    // MARK: - Caching Tests
    
    func testFetchGroups_Caching() async throws {
        // Given
        let testGroups = testEntityFactory.createGroups(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await groupService.fetchGroups()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await groupService.fetchGroups()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGroupExists_Caching() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup(name: "Cache Test Group")
        try mockCoreDataStack.save()
        
        // When - First check (should cache)
        let firstCheck = try await groupService.groupExists(withName: "Cache Test Group")
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second check (should use cache)
        let secondCheck = try await groupService.groupExists(withName: "Cache Test Group")
        
        // Then
        XCTAssertTrue(firstCheck)
        XCTAssertTrue(secondCheck) // Should return cached result
    }
    
    func testGetGroupsCount_Caching() async throws {
        // Given
        let testGroups = testEntityFactory.createGroups(count: 3)
        try mockCoreDataStack.save()
        
        // When - First count (should cache)
        let firstCount = try await groupService.getGroupsCount()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second count (should use cache)
        let secondCount = try await groupService.getGroupsCount()
        
        // Then
        XCTAssertEqual(firstCount, 3)
        XCTAssertEqual(secondCount, 3) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateGroup_InvalidatesCache() async throws {
        // Given
        let testGroups = testEntityFactory.createGroups(count: 2)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await groupService.fetchGroups()
        
        // When
        let newGroup = try await groupService.createGroup(name: "New Group", currency: "GBP")
        
        // Then - Cache should be invalidated, so we get fresh data
        let allGroups = try await groupService.fetchGroups()
        XCTAssertEqual(allGroups.count, 3) // Should include the new group
        XCTAssertTrue(allGroups.contains { $0.name == "New Group" })
    }
    
    func testUpdateGroup_InvalidatesCache() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup(name: "Original Group")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await groupService.fetchGroups()
        
        // When
        try await groupService.updateGroup(testGroup, name: "Updated Group")
        
        // Then - Cache should be invalidated
        let updatedGroup = try await groupService.fetchGroup(by: testGroup.id!)
        XCTAssertEqual(updatedGroup?.name, "Updated Group")
    }
    
    func testDeleteGroup_InvalidatesCache() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await groupService.fetchGroups()
        
        // When
        try await groupService.deleteGroup(testGroup)
        
        // Then - Cache should be invalidated
        let allGroups = try await groupService.fetchGroups()
        XCTAssertEqual(allGroups.count, 0) // Should reflect deletion
    }
}
