import Foundation
import CoreData

/// Service class for UserGroup entity operations
/// Handles all CRUD operations for UserGroup with proper threading
class UserGroupService: CoreDataService, UserGroupServiceProtocol {
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - UserGroup CRUD Operations
    
    /// Fetch all user groups
    func fetchUserGroups() async throws -> [UserGroup] {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Fetch user group by ID
    func fetchUserGroup(by id: UUID) async throws -> UserGroup? {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new user group relationship
    func createUserGroup(user: User, group: Group, role: String = "member") async throws -> UserGroup {
        try await context.perform {
            let userGroup = UserGroup(context: self.context)
            userGroup.id = UUID()
            userGroup.user = user
            userGroup.group = group
            userGroup.role = role
            userGroup.joinedAt = Date()
            
            try self.context.save()
            return userGroup
        }
    }
    
    /// Update an existing user group
    func updateUserGroup(_ userGroup: UserGroup, role: String? = nil) async throws {
        try await context.perform {
            if let role = role {
                userGroup.role = role
            }
            // UserGroup doesn't have updatedAt, using joinedAt instead
            
            try self.context.save()
        }
    }
    
    /// Delete a user group relationship
    func deleteUserGroup(_ userGroup: UserGroup) async throws {
        await delete(userGroup)
        try await save()
    }
    
    /// Get user groups for a specific user
    func getUserGroups(for user: User) async throws -> [UserGroup] {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Get user groups for a specific group
    func getUserGroups(for group: Group) async throws -> [UserGroup] {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Get users in a specific group
    func getUsers(in group: Group) async throws -> [User] {
        let userGroups = try await getUserGroups(for: group)
        return userGroups.compactMap { $0.user }
    }
    
    /// Get groups for a specific user
    func getGroups(for user: User) async throws -> [Group] {
        let userGroups = try await getUserGroups(for: user)
        return userGroups.compactMap { $0.group }
    }
    
    /// Check if user is member of group
    func isUser(_ user: User, memberOf group: Group) async throws -> Bool {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND group == %@", user, group)
        request.fetchLimit = 1
        
        let count = try await count(request)
        return count > 0
    }
    
    /// Get user group count
    func getUserGroupsCount() async throws -> Int {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        return try await count(request)
    }
}
