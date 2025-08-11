//
//  UserGroupViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class UserGroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of user-group relationships for SwiftUI binding
    @Published var userGroups: [UserGroup] = []
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error message for user feedback
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    /// Initialize with a managed object context
    /// - Parameter context: The Core Data context to use for operations
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchUserGroups()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all user-group relationships from Core Data
    func fetchUserGroups() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserGroup.group?.name, ascending: true),
            NSSortDescriptor(keyPath: \UserGroup.role, ascending: false)
        ]
        
        do {
            userGroups = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch user groups: \(error.localizedDescription)"
            print("Error fetching user groups: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new user-group relationship
    /// - Parameters:
    ///   - user: The user to add to the group
    ///   - group: The group to add the user to
    ///   - role: The user's role in the group (defaults to "owner")
    /// - Returns: The created relationship or nil if failed
    func createUserGroup(user: User, group: Group, role: String = "owner") -> UserGroup? {
        isLoading = true
        errorMessage = nil
        
        // Check if user is already in the group
        guard !userAlreadyInGroup(user, group) else {
            errorMessage = "User is already a member of this group"
            isLoading = false
            return nil
        }
        
        // Validate role
        guard isValidRole(role) else {
            errorMessage = "Invalid role. Must be one of: owner, admin, member, viewer"
            isLoading = false
            return nil
        }
        
        let newUserGroup = UserGroup(context: context)
        newUserGroup.id = UUID()
        newUserGroup.user = user
        newUserGroup.group = group
        newUserGroup.role = role
        newUserGroup.joinedAt = Date()
        
        do {
            try context.save()
            fetchUserGroups() // Refresh the list
            isLoading = false
            return newUserGroup
        } catch {
            context.rollback()
            errorMessage = "Failed to create user group: \(error.localizedDescription)"
            print("Error creating user group: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Update an existing user-group relationship
    /// - Parameters:
    ///   - userGroup: The relationship to update
    ///   - role: New role (optional)
    /// - Returns: True if update was successful
    func updateUserGroup(_ userGroup: UserGroup, role: String? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        if let role = role {
            // Validate role
            guard isValidRole(role) else {
                errorMessage = "Invalid role. Must be one of: owner, admin, member, viewer"
                isLoading = false
                return false
            }
            
            userGroup.role = role
        }
        
        do {
            try context.save()
            fetchUserGroups() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update user group: \(error.localizedDescription)"
            print("Error updating user group: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete a user-group relationship
    /// - Parameter userGroup: The relationship to delete
    /// - Returns: True if deletion was successful
    func deleteUserGroup(_ userGroup: UserGroup) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Check if this is the last owner of the group
        let isOwner = userGroup.role == "owner"
        if isOwner {
            let group = userGroup.group
            let ownersInGroup = userGroups.filter { userGroup in
                guard let userGroupRole = userGroup.role else { return false }
                return userGroup.group?.id == group?.id && userGroupRole == "owner"
            }
            if ownersInGroup.count <= 1 {
                errorMessage = "Cannot remove the last owner from a group"
                isLoading = false
                return false
            }
        }
        
        context.delete(userGroup)
        
        do {
            try context.save()
            fetchUserGroups() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete user group: \(error.localizedDescription)"
            print("Error deleting user group: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get user-group relationship by ID
    /// - Parameter id: The relationship ID to search for
    /// - Returns: The relationship if found, nil otherwise
    func userGroup(with id: UUID) -> UserGroup? {
        return userGroups.first { $0.id == id }
    }
    
    /// Check if a user is already in a group
    /// - Parameters:
    ///   - user: The user to check
    ///   - group: The group to check
    /// - Returns: True if user is already in the group
    func userAlreadyInGroup(_ user: User, _ group: Group) -> Bool {
        return userGroups.contains { userGroup in
            userGroup.user?.id == user.id && userGroup.group?.id == group.id
        }
    }
    
    /// Get user-group relationships for a specific user
    /// - Parameter user: The user to filter by
    /// - Returns: Array of relationships for the user
    func userGroups(for user: User) -> [UserGroup] {
        return userGroups.filter { $0.user?.id == user.id }
    }
    
    /// Get user-group relationships for a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of relationships for the group
    func userGroups(for group: Group) -> [UserGroup] {
        return userGroups.filter { $0.group?.id == group.id }
    }
    
    /// Get users in a specific group
    /// - Parameter group: The group to get users for
    /// - Returns: Array of users in the group
    func users(in group: Group) -> [User] {
        let groupUserGroups = userGroups(for: group)
        return groupUserGroups.compactMap { $0.user }
    }
    
    /// Get groups for a specific user
    /// - Parameter user: The user to get groups for
    /// - Returns: Array of groups the user belongs to
    func groups(for user: User) -> [Group] {
        let userUserGroups = userGroups(for: user)
        return userUserGroups.compactMap { $0.group }
    }
    
    /// Get user-group relationships with a specific role
    /// - Parameter role: The role to filter by
    /// - Returns: Array of relationships with the specified role
    func userGroups(withRole role: String) -> [UserGroup] {
        return userGroups.filter { userGroup in
            guard let userGroupRole = userGroup.role else { return false }
            return userGroupRole.lowercased() == role.lowercased()
        }
    }
    
    /// Get owners of a specific group
    /// - Parameter group: The group to get owners for
    /// - Returns: Array of user-group relationships for owners
    func owners(of group: Group) -> [UserGroup] {
        return userGroups(for: group).filter { userGroup in
            guard let userGroupRole = userGroup.role else { return false }
            return userGroupRole == "owner"
        }
    }
    
    /// Get admins of a specific group
    /// - Parameter group: The group to get admins for
    /// - Returns: Array of user-group relationships for admins
    func admins(of group: Group) -> [UserGroup] {
        return userGroups(for: group).filter { userGroup in
            guard let userGroupRole = userGroup.role else { return false }
            return userGroupRole == "admin"
        }
    }
    
    /// Check if a user is an owner of a group
    /// - Parameters:
    ///   - user: The user to check
    ///   - group: The group to check
    /// - Returns: True if user is an owner
    func isUserOwner(_ user: User, of group: Group) -> Bool {
        return userGroups.contains { userGroup in
            guard let userGroupRole = userGroup.role else { return false }
            return userGroup.user?.id == user.id && 
            userGroup.group?.id == group.id && 
            userGroupRole == "owner"
        }
    }
    
    /// Check if a user is an admin of a group
    /// - Parameters:
    ///   - user: The user to check
    ///   - group: The group to check
    /// - Returns: True if user is an admin
    func isUserAdmin(_ user: User, of group: Group) -> Bool {
        return userGroups.contains { userGroup in
            guard let userGroupRole = userGroup.role else { return false }
            return userGroup.user?.id == user.id && 
            userGroup.group?.id == group.id && 
            userGroupRole == "admin"
        }
    }
    
    /// Get user-group relationships sorted by role priority
    /// - Returns: Array of relationships sorted by role priority
    func userGroupsSortedByRole() -> [UserGroup] {
        return userGroups.sorted { userGroup1, userGroup2 in
            let priority1 = rolePriority(for: userGroup1.role ?? "")
            let priority2 = rolePriority(for: userGroup2.role ?? "")
            return priority1 > priority2
        }
    }
    
    /// Helper method to get role priority
    private func rolePriority(for role: String) -> Int {
        switch role.lowercased() {
        case "owner": return 4
        case "admin": return 3
        case "member": return 2
        case "viewer": return 1
        default: return 0
        }
    }
    
    /// Get user-group relationships sorted by join date (newest first)
    /// - Returns: Array of relationships sorted by join date
    func userGroupsSortedByJoinDate() -> [UserGroup] {
        return userGroups.sorted { userGroup1, userGroup2 in
            let date1 = userGroup1.joinedAt ?? Date.distantPast
            let date2 = userGroup2.joinedAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /// Validate role string
    /// - Parameter role: The role to validate
    /// - Returns: True if role is valid
    private func isValidRole(_ role: String) -> Bool {
        let validRoles = ["owner", "admin", "member", "viewer"]
        return validRoles.contains(role.lowercased())
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
