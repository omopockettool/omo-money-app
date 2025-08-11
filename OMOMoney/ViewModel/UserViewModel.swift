//
//  UserViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of users for SwiftUI binding
    @Published var users: [User] = []
    
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
        fetchUsers()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all users from Core Data
    func fetchUsers() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        
        do {
            users = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch users: \(error.localizedDescription)"
            print("Error fetching users: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new user
    /// - Parameters:
    ///   - name: The user name
    ///   - email: The user email (required)
    /// - Returns: The created user or nil if failed
    func createUser(name: String, email: String) -> User? {
        isLoading = true
        errorMessage = nil
        
        // Validate email
        guard isValidEmail(email) else {
            errorMessage = "Invalid email format"
            isLoading = false
            return nil
        }
        
        // Check if email already exists
        guard !userEmailExists(email) else {
            errorMessage = "User with this email already exists"
            isLoading = false
            return nil
        }
        
        let newUser = User(context: context, name: name, email: email)
        
        do {
            try context.save()
            fetchUsers() // Refresh the list
            isLoading = false
            return newUser
        } catch {
            context.rollback()
            errorMessage = "Failed to create user: \(error.localizedDescription)"
            print("Error creating user: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Update an existing user
    /// - Parameters:
    ///   - user: The user to update
    ///   - name: New name (optional)
    ///   - email: New email (optional)
    /// - Returns: True if update was successful
    func updateUser(_ user: User, name: String? = nil, email: String? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        if let name = name {
            user.name = name
        }
        
        if let email = email {
            // Validate email
            guard isValidEmail(email) else {
                errorMessage = "Invalid email format"
                isLoading = false
                return false
            }
            
            // Check if email already exists (excluding current user)
            guard !userEmailExists(email, excluding: user) else {
                errorMessage = "User with this email already exists"
                isLoading = false
                return false
            }
            
            user.email = email
        }
        
        user.updateTimestamp()
        
        do {
            try context.save()
            fetchUsers() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update user: \(error.localizedDescription)"
            print("Error updating user: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete a user
    /// - Parameter user: The user to delete
    /// - Returns: True if deletion was successful
    func deleteUser(_ user: User) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Check if user belongs to any groups before deletion
        if user.belongsToGroups {
            errorMessage = "Cannot delete user who belongs to groups"
            isLoading = false
            return false
        }
        
        context.delete(user)
        
        do {
            try context.save()
            fetchUsers() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete user: \(error.localizedDescription)"
            print("Error deleting user: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get user by ID
    /// - Parameter id: The user ID to search for
    /// - Returns: The user if found, nil otherwise
    func user(with id: UUID) -> User? {
        return users.first { $0.id == id }
    }
    
    /// Get user by email
    /// - Parameter email: The email to search for
    /// - Returns: The user if found, nil otherwise
    func user(withEmail email: String) -> User? {
        return users.first { $0.email.lowercased() == email.lowercased() }
    }
    
    /// Check if a user email already exists
    /// - Parameters:
    ///   - email: The email to check
    ///   - excludeUser: User to exclude from check (for updates)
    /// - Returns: True if email already exists
    func userEmailExists(_ email: String, excluding excludeUser: User? = nil) -> Bool {
        return users.contains { user in
            user.email.lowercased() == email.lowercased() &&
            user.id != excludeUser?.id
        }
    }
    
    /// Get users who belong to a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of users in the group
    func users(in group: Group) -> [User] {
        return users.filter { user in
            user.groups.contains { $0.id == group.id }
        }
    }
    
    /// Get users with a specific role
    /// - Parameter role: The role to filter by
    /// - Returns: Array of users with the specified role
    func users(withRole role: String) -> [User] {
        return users.filter { user in
            user.roles.contains { $0.lowercased() == role.lowercased() }
        }
    }
    
    /// Get users who are owners
    /// - Returns: Array of users who are owners in any group
    func ownerUsers() -> [User] {
        return users.filter { $0.isOwner }
    }
    
    /// Get users who are admins
    /// - Returns: Array of users who have admin privileges
    func adminUsers() -> [User] {
        return users.filter { $0.hasAdminPrivileges }
    }
    
    /// Get users sorted by name
    /// - Returns: Array of users sorted alphabetically by name
    func usersSortedByName() -> [User] {
        return users.sorted { user1, user2 in
            user1.displayName.localizedCaseInsensitiveCompare(user2.displayName) == .orderedAscending
        }
    }
    
    /// Get users sorted by group count (highest first)
    /// - Returns: Array of users sorted by number of groups
    func usersSortedByGroupCount() -> [User] {
        return users.sorted { $0.groupCount > $1.groupCount }
    }
    
    /// Get users sorted by creation date (newest first)
    /// - Returns: Array of users sorted by creation date
    func usersSortedByCreationDate() -> [User] {
        return users.sorted { user1, user2 in
            let date1 = user1.createdAt ?? Date.distantPast
            let date2 = user2.createdAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /// Validate email format
    /// - Parameter email: The email to validate
    /// - Returns: True if email format is valid
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
