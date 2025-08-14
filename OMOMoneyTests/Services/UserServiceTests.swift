import XCTest
import CoreData
@testable import OMOMoney

final class UserServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var userService: UserService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        userService = UserService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create User Tests
    
    func testCreateUser_Success() async throws {
        // Given
        let userName = "John Doe"
        let userEmail = "john@example.com"
        
        // When
        let createdUser = try await userService.createUser(name: userName, email: userEmail)
        
        // Then
        XCTAssertNotNil(createdUser)
        XCTAssertEqual(createdUser.name, userName)
        XCTAssertEqual(createdUser.email, userEmail)
        XCTAssertNotNil(createdUser.id)
        XCTAssertNotNil(createdUser.createdAt)
        
        // Verify user was saved to Core Data
        let savedUser = try await userService.fetchUser(by: createdUser.id!)
        XCTAssertNotNil(savedUser)
        XCTAssertEqual(savedUser?.name, userName)
    }
    
    func testCreateUser_WithoutEmail() async throws {
        // Given
        let userName = "Jane Doe"
        
        // When
        let createdUser = try await userService.createUser(name: userName, email: nil)
        
        // Then
        XCTAssertNotNil(createdUser)
        XCTAssertEqual(createdUser.name, userName)
        XCTAssertNil(createdUser.email)
    }
    
    // MARK: - Fetch User Tests
    
    func testFetchUsers_Empty() async throws {
        // When
        let users = try await userService.fetchUsers()
        
        // Then
        XCTAssertTrue(users.isEmpty)
    }
    
    func testFetchUsers_WithData() async throws {
        // Given
        let testUsers = testEntityFactory.createUsers(count: 3)
        try mockCoreDataStack.save()
        
        // When
        let fetchedUsers = try await userService.fetchUsers()
        
        // Then
        XCTAssertEqual(fetchedUsers.count, 3)
        XCTAssertTrue(fetchedUsers.allSatisfy { $0.name?.contains("User") == true })
    }
    
    func testFetchUser_ById() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        try mockCoreDataStack.save()
        
        // When
        let fetchedUser = try await userService.fetchUser(by: testUser.id!)
        
        // Then
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.id, testUser.id)
        XCTAssertEqual(fetchedUser?.name, testUser.name)
    }
    
    func testFetchUser_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedUser = try await userService.fetchUser(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedUser)
    }
    
    // MARK: - Update User Tests
    
    func testUpdateUser_Success() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        try mockCoreDataStack.save()
        
        let newName = "Updated Name"
        let newEmail = "updated@example.com"
        
        // When
        try await userService.updateUser(testUser, name: newName, email: newEmail)
        
        // Then
        XCTAssertEqual(testUser.name, newName)
        XCTAssertEqual(testUser.email, newEmail)
        XCTAssertNotNil(testUser.lastModifiedAt)
        
        // Verify changes were saved
        let updatedUser = try await userService.fetchUser(by: testUser.id!)
        XCTAssertEqual(updatedUser?.name, newName)
        XCTAssertEqual(updatedUser?.email, newEmail)
    }
    
    func testUpdateUser_PartialUpdate() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        try mockCoreDataStack.save()
        
        let originalName = testUser.name
        let newEmail = "partial@example.com"
        
        // When
        try await userService.updateUser(testUser, name: nil, email: newEmail)
        
        // Then
        XCTAssertEqual(testUser.name, originalName) // Name unchanged
        XCTAssertEqual(testUser.email, newEmail) // Email updated
        XCTAssertNotNil(testUser.lastModifiedAt)
    }
    
    // MARK: - Delete User Tests
    
    func testDeleteUser_Success() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        try mockCoreDataStack.save()
        
        // When
        try await userService.deleteUser(testUser)
        
        // Then
        let deletedUser = try await userService.fetchUser(by: testUser.id!)
        XCTAssertNil(deletedUser)
    }
    
    // MARK: - Validation Tests
    
    func testUserExists_True() async throws {
        // Given
        let testUser = testEntityFactory.createUser(name: "Unique Name")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await userService.userExists(withName: "Unique Name")
        
        // Then
        XCTAssertTrue(exists)
    }
    
    func testUserExists_False() async throws {
        // Given
        let testUser = testEntityFactory.createUser(name: "Existing Name")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await userService.userExists(withName: "Non Existent Name")
        
        // Then
        XCTAssertFalse(exists)
    }
    
    func testUserExists_ExcludingUserId() async throws {
        // Given
        let user1 = testEntityFactory.createUser(name: "Same Name")
        let user2 = testEntityFactory.createUser(name: "Same Name")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await userService.userExists(withName: "Same Name", excluding: user1.id)
        
        // Then
        XCTAssertTrue(exists) // Should find user2
    }
    
    func testUserExists_ExcludingUserIdNotFound() async throws {
        // Given
        let testUser = testEntityFactory.createUser(name: "Unique Name")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await userService.userExists(withName: "Unique Name", excluding: UUID())
        
        // Then
        XCTAssertTrue(exists) // Should find the user
    }
    
    // MARK: - Count Tests
    
    func testGetUsersCount_Empty() async throws {
        // When
        let count = try await userService.getUsersCount()
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testGetUsersCount_WithData() async throws {
        // Given
        let testUsers = testEntityFactory.createUsers(count: 5)
        try mockCoreDataStack.save()
        
        // When
        let count = try await userService.getUsersCount()
        
        // Then
        XCTAssertEqual(count, 5)
    }
    
    // MARK: - Caching Tests
    
    func testFetchUsers_Caching() async throws {
        // Given
        let testUsers = testEntityFactory.createUsers(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await userService.fetchUsers()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await userService.fetchUsers()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testUserExists_Caching() async throws {
        // Given
        let testUser = testEntityFactory.createUser(name: "Cache Test")
        try mockCoreDataStack.save()
        
        // When - First check (should cache)
        let firstCheck = try await userService.userExists(withName: "Cache Test")
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second check (should use cache)
        let secondCheck = try await userService.userExists(withName: "Cache Test")
        
        // Then
        XCTAssertTrue(firstCheck)
        XCTAssertTrue(secondCheck) // Should return cached result
    }
    
    func testGetUsersCount_Caching() async throws {
        // Given
        let testUsers = testEntityFactory.createUsers(count: 3)
        try mockCoreDataStack.save()
        
        // When - First count (should cache)
        let firstCount = try await userService.getUsersCount()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second count (should use cache)
        let secondCount = try await userService.getUsersCount()
        
        // Then
        XCTAssertEqual(firstCount, 3)
        XCTAssertEqual(secondCount, 3) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateUser_InvalidatesCache() async throws {
        // Given
        let testUsers = testEntityFactory.createUsers(count: 2)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userService.fetchUsers()
        
        // When
        _ = try await userService.createUser(name: "New User", email: "new@example.com")
        
        // Then - Cache should be invalidated, so we get fresh data
        let allUsers = try await userService.fetchUsers()
        XCTAssertEqual(allUsers.count, 3) // Should include the new user
        XCTAssertTrue(allUsers.contains { $0.name == "New User" })
    }
    
    func testUpdateUser_InvalidatesCache() async throws {
        // Given
        let testUser = testEntityFactory.createUser(name: "Original Name")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userService.fetchUsers()
        
        // When
        try await userService.updateUser(testUser, name: "Updated Name")
        
        // Then - Cache should be invalidated
        let updatedUser = try await userService.fetchUser(by: testUser.id!)
        XCTAssertEqual(updatedUser?.name, "Updated Name")
    }
    
    func testDeleteUser_InvalidatesCache() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userService.fetchUsers()
        
        // When
        try await userService.deleteUser(testUser)
        
        // Then - Cache should be invalidated
        let allUsers = try await userService.fetchUsers()
        XCTAssertEqual(allUsers.count, 0) // Should reflect deletion
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateUser_InvalidContext() async {
        // Given
        let invalidContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let invalidService = UserService(context: invalidContext)
        
        // When & Then
        do {
            _ = try await invalidService.createUser(name: "Test", email: "test@example.com")
            XCTFail("Should throw an error")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is NSError)
        }
    }
    
    func testUpdateUser_InvalidContext() async {
        // Given
        let invalidContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let invalidService = UserService(context: invalidContext)
        let testUser = testEntityFactory.createUser()
        
        // When & Then
        do {
            try await invalidService.updateUser(testUser, name: "Updated")
            XCTFail("Should throw an error")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is NSError)
        }
    }
}
