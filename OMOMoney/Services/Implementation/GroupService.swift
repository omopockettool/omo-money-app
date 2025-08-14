import Foundation
import CoreData

/// Service class for Group entity operations
/// Handles all CRUD operations for Group with proper threading
class GroupService: CoreDataService, GroupServiceProtocol {
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Group CRUD Operations
    
    /// Fetch all groups
    func fetchGroups() async throws -> [Group] {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
        return try await fetch(request)
    }
    
    /// Fetch group by ID
    func fetchGroup(by id: UUID) async throws -> Group? {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new group
    func createGroup(name: String, currency: String) async throws -> Group {
        try await context.perform {
            let group = Group(context: self.context)
            group.id = UUID()
            group.name = name
            group.currency = currency
            group.createdAt = Date()
            
            try self.context.save()
            return group
        }
    }
    
    /// Update an existing group
    func updateGroup(_ group: Group, name: String? = nil, currency: String? = nil) async throws {
        try await context.perform {
            if let name = name {
                group.name = name
            }
            if let currency = currency {
                group.currency = currency
            }
            group.lastModifiedAt = Date()
            
            try self.context.save()
        }
    }
    
    /// Delete a group
    func deleteGroup(_ group: Group) async throws {
        await delete(group)
        try await save()
    }
    
    /// Check if group exists by name
    func groupExists(withName name: String, excluding groupId: UUID? = nil) async throws -> Bool {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        
        if let groupId = groupId {
            request.predicate = NSPredicate(format: "name == %@ AND id != %@", name, groupId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "name == %@", name)
        }
        
        let count = try await count(request)
        return count > 0
    }
    
    /// Get groups count
    func getGroupsCount() async throws -> Int {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        return try await count(request)
    }
    
    /// Get groups by owner (through UserGroup relationship)
    /// This method requires UserGroupService to work properly
    func getGroups(ownedBy user: User) async throws -> [Group] {
        // This method should be implemented in UserGroupService instead
        // as Group doesn't have a direct owner relationship
        throw NSError(domain: "GroupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Use UserGroupService.getGroups(for:) instead"])
    }
}
