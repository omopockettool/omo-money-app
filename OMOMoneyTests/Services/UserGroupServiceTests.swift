import XCTest
import CoreData
@testable import OMOMoney

final class UserGroupServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var userGroupService: UserGroupService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        userGroupService = UserGroupService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create UserGroup Tests
    
    func testCreateUserGroup_Success() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let testGroup = testEntityFactory.createGroup()
        let role = "member"
        try mockCoreDataStack.save()
        
        // When
        let createdUserGroup = try await userGroupService.createUserGroup(
            user: testUser,
            group: testGroup,
            role: role
        )
        
        // Then
        XCTAssertNotNil(createdUserGroup)
        XCTAssertEqual(createdUserGroup.user, testUser)
        XCTAssertEqual(createdUserGroup.group, testGroup)
        XCTAssertEqual(createdUserGroup.role, role)
        XCTAssertNotNil(createdUserGroup.id)
        XCTAssertNotNil(createdUserGroup.joinedAt)
        
        // Verify userGroup was saved to Core Data
        let savedUserGroup = try await userGroupService.fetchUserGroup(by: createdUserGroup.id!)
        XCTAssertNotNil(savedUserGroup)
        XCTAssertEqual(savedUserGroup?.user, testUser)
        XCTAssertEqual(savedUserGroup?.group, testGroup)
    }
    
    // MARK: - Fetch UserGroup Tests
    
    func testFetchUserGroups_Empty() async throws {
        // When
        let userGroups = try await userGroupService.fetchUserGroups()
        
        // Then
        XCTAssertTrue(userGroups.isEmpty)
    }
    
    func testFetchUserGroups_WithData() async throws {
        // Given
        let testUserGroups = testEntityFactory.createUserGroups(
            users: testEntityFactory.createUsers(count: 2),
            groups: testEntityFactory.createGroups(count: 2)
        )
        try mockCoreDataStack.save()
        
        // When
        let fetchedUserGroups = try await userGroupService.fetchUserGroups()
        
        // Then
        XCTAssertEqual(fetchedUserGroups.count, 2)
        XCTAssertTrue(fetchedUserGroups.allSatisfy { $0.user != nil && $0.group != nil })
    }
    
    func testFetchUserGroup_ById() async throws {
        // Given
        let testUserGroup = testEntityFactory.createUserGroup(
            user: testEntityFactory.createUser(),
            group: testEntityFactory.createGroup()
        )
        try mockCoreDataStack.save()
        
        // When
        let fetchedUserGroup = try await userGroupService.fetchUserGroup(by: testUserGroup.id!)
        
        // Then
        XCTAssertNotNil(fetchedUserGroup)
        XCTAssertEqual(fetchedUserGroup?.id, testUserGroup.id)
        XCTAssertEqual(fetchedUserGroup?.user, testUserGroup.user)
        XCTAssertEqual(fetchedUserGroup?.group, testUserGroup.group)
    }
    
    func testFetchUserGroup_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedUserGroup = try await userGroupService.fetchUserGroup(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedUserGroup)
    }
    
    // MARK: - Relationship Tests
    
    func testGetUserGroups_ForUser() async throws {
        // Given
        let user1 = testEntityFactory.createUser(name: "User 1")
        let user2 = testEntityFactory.createUser(name: "User 2")
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        
        let userGroup1 = testEntityFactory.createUserGroup(user: user1, group: group1)
        let userGroup2 = testEntityFactory.createUserGroup(user: user1, group: group2)
        let userGroup3 = testEntityFactory.createUserGroup(user: user2, group: group1)
        
        try mockCoreDataStack.save()
        
        // When
        let user1Groups = try await userGroupService.getUserGroups(for: user1)
        let user2Groups = try await userGroupService.getUserGroups(for: user2)
        
        // Then
        XCTAssertEqual(user1Groups.count, 2)
        XCTAssertEqual(user2Groups.count, 1)
        XCTAssertTrue(user1Groups.allSatisfy { $0.user == user1 })
        XCTAssertTrue(user2Groups.allSatisfy { $0.user == user2 })
    }
    
    func testGetUserGroups_ForGroup() async throws {
        // Given
        let user1 = testEntityFactory.createUser(name: "User 1")
        let user2 = testEntityFactory.createUser(name: "User 2")
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        
        let userGroup1 = testEntityFactory.createUserGroup(user: user1, group: group1)
        let userGroup2 = testEntityFactory.createUserGroup(user: user2, group: group1)
        let userGroup3 = testEntityFactory.createUserGroup(user: user1, group: group2)
        
        try mockCoreDataStack.save()
        
        // When
        let group1Users = try await userGroupService.getUserGroups(for: group1)
        let group2Users = try await userGroupService.getUserGroups(for: group2)
        
        // Then
        XCTAssertEqual(group1Users.count, 2)
        XCTAssertEqual(group2Users.count, 1)
        XCTAssertTrue(group1Users.allSatisfy { $0.group == group1 })
        XCTAssertTrue(group2Users.allSatisfy { $0.group == group2 })
    }
    
    func testGetUsers_InGroup() async throws {
        // Given
        let user1 = testEntityFactory.createUser(name: "User 1")
        let user2 = testEntityFactory.createUser(name: "User 2")
        let testGroup = testEntityFactory.createGroup()
        
        let userGroup1 = testEntityFactory.createUserGroup(user: user1, group: testGroup)
        let userGroup2 = testEntityFactory.createUserGroup(user: user2, group: testGroup)
        
        try mockCoreDataStack.save()
        
        // When
        let usersInGroup = try await userGroupService.getUsers(in: testGroup)
        
        // Then
        XCTAssertEqual(usersInGroup.count, 2)
        XCTAssertTrue(usersInGroup.contains(user1))
        XCTAssertTrue(usersInGroup.contains(user2))
    }
    
    func testGetGroups_ForUser() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        
        let userGroup1 = testEntityFactory.createUserGroup(user: testUser, group: group1)
        let userGroup2 = testEntityFactory.createUserGroup(user: testUser, group: group2)
        
        try mockCoreDataStack.save()
        
        // When
        let groupsForUser = try await userGroupService.getGroups(for: testUser)
        
        // Then
        XCTAssertEqual(groupsForUser.count, 2)
        XCTAssertTrue(groupsForUser.contains(group1))
        XCTAssertTrue(groupsForUser.contains(group2))
    }
    
    func testIsUser_MemberOfGroup() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let testGroup = testEntityFactory.createGroup()
        let userGroup = testEntityFactory.createUserGroup(user: testUser, group: testGroup)
        try mockCoreDataStack.save()
        
        // When
        let isMember = try await userGroupService.isUser(testUser, memberOf: testGroup)
        
        // Then
        XCTAssertTrue(isMember)
    }
    
    func testIsUser_NotMemberOfGroup() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let isMember = try await userGroupService.isUser(testUser, memberOf: testGroup)
        
        // Then
        XCTAssertFalse(isMember)
    }
    
    // MARK: - Update UserGroup Tests
    
    func testUpdateUserGroup_Success() async throws {
        // Given
        let testUserGroup = testEntityFactory.createUserGroup(
            user: testEntityFactory.createUser(),
            group: testEntityFactory.createGroup()
        )
        try mockCoreDataStack.save()
        
        let newRole = "admin"
        
        // When
        try await userGroupService.updateUserGroup(testUserGroup, role: newRole)
        
        // Then
        XCTAssertEqual(testUserGroup.role, newRole)
        
        // Verify changes were saved
        let updatedUserGroup = try await userGroupService.fetchUserGroup(by: testUserGroup.id!)
        XCTAssertEqual(updatedUserGroup?.role, newRole)
    }
    
    // MARK: - Delete UserGroup Tests
    
    func testDeleteUserGroup_Success() async throws {
        // Given
        let testUserGroup = testEntityFactory.createUserGroup(
            user: testEntityFactory.createUser(),
            group: testEntityFactory.createGroup()
        )
        try mockCoreDataStack.save()
        
        // When
        try await userGroupService.deleteUserGroup(testUserGroup)
        
        // Then
        let deletedUserGroup = try await userGroupService.fetchUserGroup(by: testUserGroup.id!)
        XCTAssertNil(deletedUserGroup)
    }
    
    // MARK: - Caching Tests
    
    func testFetchUserGroups_Caching() async throws {
        // Given
        let testUserGroups = testEntityFactory.createUserGroups(
            users: testEntityFactory.createUsers(count: 2),
            groups: testEntityFactory.createGroups(count: 2)
        )
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await userGroupService.fetchUserGroups()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await userGroupService.fetchUserGroups()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetUserGroupsForUser_Caching() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        _ = testEntityFactory.createGroups(count: 2)
        let testUserGroups = testEntityFactory.createUserGroups(users: [testUser], groups: testGroups)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await userGroupService.getUserGroups(for: testUser)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await userGroupService.getUserGroups(for: testUser)
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetUserGroupsForGroup_Caching() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createUsers(count: 2)
        let testUserGroups = testEntityFactory.createUserGroups(users: testUsers, groups: [testGroup])
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await userGroupService.getUserGroups(for: testGroup)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await userGroupService.getUserGroups(for: testGroup)
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testIsUserMemberOfGroup_Caching() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let testGroup = testEntityFactory.createGroup()
        let userGroup = testEntityFactory.createUserGroup(user: testUser, group: testGroup)
        try mockCoreDataStack.save()
        
        // When - First check (should cache)
        let firstCheck = try await userGroupService.isUser(testUser, memberOf: testGroup)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second check (should use cache)
        let secondCheck = try await userGroupService.isUser(testUser, memberOf: testGroup)
        
        // Then
        XCTAssertTrue(firstCheck)
        XCTAssertTrue(secondCheck) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateUserGroup_InvalidatesCache() async throws {
        // Given
        let testUser = testEntityFactory.createUser()
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userGroupService.getUserGroups(for: testUser)
        _ = try await userGroupService.getUserGroups(for: testGroup)
        _ = try await userGroupService.isUser(testUser, memberOf: testGroup)
        
        // When
        _ = try await userGroupService.createUserGroup(
            user: testUser,
            group: testGroup,
            role: "member"
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let userGroups = try await userGroupService.getUserGroups(for: testUser)
        XCTAssertEqual(userGroups.count, 1) // Should include the new userGroup
    }
    
    func testUpdateUserGroup_InvalidatesCache() async throws {
        // Given
        let testUserGroup = testEntityFactory.createUserGroup(
            user: testEntityFactory.createUser(),
            group: testEntityFactory.createGroup()
        )
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userGroupService.fetchUserGroups()
        
        // When
        try await userGroupService.updateUserGroup(testUserGroup, role: "admin")
        
        // Then - Cache should be invalidated
        let updatedUserGroup = try await userGroupService.fetchUserGroup(by: testUserGroup.id!)
        XCTAssertEqual(updatedUserGroup?.role, "admin")
    }
    
    func testDeleteUserGroup_InvalidatesCache() async throws {
        // Given
        let testUserGroup = testEntityFactory.createUserGroup(
            user: testEntityFactory.createUser(),
            group: testEntityFactory.createGroup()
        )
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await userGroupService.fetchUserGroups()
        
        // When
        try await userGroupService.deleteUserGroup(testUserGroup)
        
        // Then - Cache should be invalidated
        let allUserGroups = try await userGroupService.fetchUserGroups()
        XCTAssertEqual(allUserGroups.count, 0) // Should reflect deletion
    }
}
