//
//  GroupViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class GroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of groups for SwiftUI binding
    @Published var groups: [Group] = []
    
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
        fetchGroups()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all groups from Core Data
    func fetchGroups() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
        
        do {
            groups = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
            print("Error fetching groups: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new group
    /// - Parameters:
    ///   - name: The group name
    ///   - currency: The group currency (defaults to "USD")
    /// - Returns: The created group or nil if failed
    func createGroup(name: String, currency: String = "USD") -> Group? {
        isLoading = true
        errorMessage = nil
        
        let newGroup = Group(context: context, name: name, currency: currency)
        
        do {
            try context.save()
            fetchGroups() // Refresh the list
            isLoading = false
            return newGroup
        } catch {
            context.rollback()
            errorMessage = "Failed to create group: \(error.localizedDescription)"
            print("Error creating group: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Update an existing group
    /// - Parameters:
    ///   - group: The group to update
    ///   - name: New name (optional)
    ///   - currency: New currency (optional)
    /// - Returns: True if update was successful
    func updateGroup(_ group: Group, name: String? = nil, currency: String? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        if let name = name {
            group.name = name
        }
        
        if let currency = currency {
            group.currency = currency
        }
        
        group.updateTimestamp()
        
        do {
            try context.save()
            fetchGroups() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update group: \(error.localizedDescription)"
            print("Error updating group: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete a group
    /// - Parameter group: The group to delete
    /// - Returns: True if deletion was successful
    func deleteGroup(_ group: Group) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Check if group has entries or categories before deletion
        if group.entryCount > 0 || group.categoryCount > 0 {
            errorMessage = "Cannot delete group with existing entries or categories"
            isLoading = false
            return false
        }
        
        context.delete(group)
        
        do {
            try context.save()
            fetchGroups() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
            print("Error deleting group: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get group by ID
    /// - Parameter id: The group ID to search for
    /// - Returns: The group if found, nil otherwise
    func group(with id: UUID) -> Group? {
        return groups.first { $0.id == id }
    }
    
    /// Check if a group name already exists
    /// - Parameters:
    ///   - name: The name to check
    ///   - excludeGroup: Group to exclude from check (for updates)
    /// - Returns: True if name already exists
    func groupNameExists(_ name: String, excluding excludeGroup: Group? = nil) -> Bool {
        return groups.contains { group in
            group.name?.lowercased() == name.lowercased() &&
            group.id != excludeGroup?.id
        }
    }
    
    /// Get groups with entries
    /// - Returns: Array of groups that have entries
    func groupsWithEntries() -> [Group] {
        return groups.filter { $0.hasEntries }
    }
    
    /// Get groups with categories
    /// - Returns: Array of groups that have categories
    func groupsWithCategories() -> [Group] {
        return groups.filter { $0.hasCategories }
    }
    
    /// Get groups with members
    /// - Returns: Array of groups that have members
    func groupsWithMembers() -> [Group] {
        return groups.filter { $0.hasMembers }
    }
    
    /// Get groups by currency
    /// - Parameter currency: The currency to filter by
    /// - Returns: Array of groups using the specified currency
    func groups(withCurrency currency: String) -> [Group] {
        return groups.filter { $0.currency == currency }
    }
    
    /// Calculate total amount across all groups
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmountAcrossAllGroups() -> NSDecimalNumber {
        return groups.reduce(NSDecimalNumber.zero) { total, group in
            total.adding(group.totalAmount)
        }
    }
    
    /// Get groups sorted by total amount (highest first)
    /// - Returns: Array of groups sorted by total amount
    func groupsSortedByAmount() -> [Group] {
        return groups.sorted { group1, group2 in
            group1.totalAmount.compare(group2.totalAmount) == .orderedDescending
        }
    }
    
    /// Get groups sorted by entry count (highest first)
    /// - Returns: Array of groups sorted by entry count
    func groupsSortedByEntryCount() -> [Group] {
        return groups.sorted { group1, group2 in
            group1.entryCount > group2.entryCount
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
