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
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        // Create background context for heavy operations
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueue)
        self.backgroundContext.parent = context
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
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch users: \(error.localizedDescription)"
            print("Error fetching users: \(error)")
            isLoading = false
        }
    }
    
    /// Create a new user
    /// - Parameters:
    ///   - name: User's name
    ///   - email: User's email address
    /// - Returns: True if creation was successful
    func createUser(name: String, email: String) -> Bool {
        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty"
            return false
        }
        
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Email cannot be empty"
            return false
        }
        
        // Check if email already exists
        if userEmailExists(email) {
            errorMessage = "Email already exists"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Perform creation in background
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let newUser = User(context: self.backgroundContext)
            newUser.id = UUID()
            newUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            newUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            newUser.createdAt = Date()
            newUser.lastModifiedAt = Date()
            
            do {
                try self.backgroundContext.save()
                
                // Update UI on main thread
                Task { @MainActor in
                    self.fetchUsers()
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to create user: \(error.localizedDescription)"
                    print("Error creating user: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    /// Update an existing user
    /// - Parameters:
    ///   - user: The user to update
    ///   - name: New name (optional)
    ///   - email: New email (optional)
    /// - Returns: True if update was successful
    func updateUser(_ user: User, name: String? = nil, email: String? = nil) -> Bool {
        // Validate input
        if let name = name, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Name cannot be empty"
            return false
        }
        
        if let email = email, email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Email cannot be empty"
            return false
        }
        
        // Check if email already exists (excluding current user)
        if let email = email, userEmailExists(email, excluding: user) {
            errorMessage = "Email already exists"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Perform update in background
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch user in background context
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
            
            do {
                let backgroundUser = try self.backgroundContext.fetch(request).first
                if let backgroundUser = backgroundUser {
                    if let name = name {
                        backgroundUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let email = email {
                        backgroundUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }
                    backgroundUser.lastModifiedAt = Date()
                    
                    try self.backgroundContext.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchUsers()
                    }
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to update user: \(error.localizedDescription)"
                    print("Error updating user: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    /// Delete a user
    /// - Parameter user: The user to delete
    /// - Returns: True if deletion was successful
    func deleteUser(_ user: User) -> Bool {
        // Check if user belongs to groups
        if (user.userGroups?.count ?? 0) > 0 {
            errorMessage = "Cannot delete user who belongs to groups"
            isLoading = false
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Perform deletion in background
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch user in background context
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
            
            do {
                let backgroundUser = try self.backgroundContext.fetch(request).first
                if let backgroundUser = backgroundUser {
                    self.backgroundContext.delete(backgroundUser)
                    try self.backgroundContext.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchUsers()
                    }
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to delete user: \(error.localizedDescription)"
                    print("Error deleting user: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Utility Methods
    
    /// Get user by email
    /// - Parameter email: The email to search for
    /// - Returns: The user if found, nil otherwise
    func user(withEmail email: String) -> User? {
        return users.first { user in
            guard let userEmail = user.email else { return false }
            return userEmail.lowercased() == email.lowercased()
        }
    }
    
    /// Check if an email already exists
    /// - Parameters:
    ///   - email: The email to check
    ///   - excludeUser: User to exclude from check (for updates)
    /// - Returns: True if email already exists
    func userEmailExists(_ email: String, excluding excludeUser: User? = nil) -> Bool {
        return users.contains { user in
            guard let userEmail = user.email else { return false }
            return userEmail.lowercased() == email.lowercased() &&
            user.id != excludeUser?.id
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
