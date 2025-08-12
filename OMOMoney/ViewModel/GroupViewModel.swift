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
    
    let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    /// Initialize with a managed object context
    /// - Parameter context: The Core Data context to use for operations
    init(context: NSManagedObjectContext) {
        self.context = context
        // Don't fetch groups automatically - only when needed
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all groups from Core Data
    func fetchGroups() {
        isLoading = true
        errorMessage = nil
        
        // Perform fetch in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
            
            do {
                let fetchedGroups = try self.context.fetch(request)
                
                // Update UI on main thread
                Task { @MainActor in
                    self.groups = fetchedGroups
                    self.isLoading = false
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    print("Error fetching groups: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Create a new group
    /// - Parameters:
    ///   - name: The group name
    ///   - currency: The group currency (defaults to "USD")
    /// - Returns: The created group or nil if failed
    func createGroup(name: String, currency: String = "USD") -> Group? {
        isLoading = true
        errorMessage = nil
        
        // Perform creation in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let newGroup = Group(context: self.context)
            newGroup.id = UUID()
            newGroup.name = name
            newGroup.currency = currency
            newGroup.createdAt = Date()
            newGroup.lastModifiedAt = Date()
            
            do {
                try self.context.save()
                
                // Update UI on main thread
                Task { @MainActor in
                    self.fetchGroups()
                    self.isLoading = false
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to create group: \(error.localizedDescription)"
                    print("Error creating group: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return nil // Will be updated via async callback
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
        
        // Store group ID for background operation
        guard let groupId = group.id else { return false }
        
        // Perform update in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch group in background context
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            
            do {
                let backgroundGroup = try self.context.fetch(request).first
                if let backgroundGroup = backgroundGroup {
                    if let name = name {
                        backgroundGroup.name = name
                    }
                    if let currency = currency {
                        backgroundGroup.currency = currency
                    }
                    backgroundGroup.lastModifiedAt = Date()
                    
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchGroups()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to update group: \(error.localizedDescription)"
                    print("Error updating group: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    /// Delete a group
    /// - Parameter group: The group to delete
    /// - Returns: True if deletion was successful
    func deleteGroup(_ group: Group) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Store group ID for background operation
        guard let groupId = group.id else { return false }
        
        // Perform deletion in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch group in background context
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            
            do {
                let backgroundGroup = try self.context.fetch(request).first
                if let backgroundGroup = backgroundGroup {
                    // Check if group has entries or categories before deletion
                    let entryCount = (backgroundGroup.entries?.count ?? 0)
                    let categoryCount = (backgroundGroup.categories?.count ?? 0)
                    if entryCount > 0 || categoryCount > 0 {
                        Task { @MainActor in
                            self.errorMessage = "Cannot delete group with existing entries or categories"
                            self.isLoading = false
                        }
                        return
                    }
                    
                    self.context.delete(backgroundGroup)
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchGroups()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to delete group: \(error.localizedDescription)"
                    print("Error deleting group: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
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
            guard let groupName = group.name else { return false }
            return groupName.lowercased() == name.lowercased() &&
            group.id != excludeGroup?.id
        }
    }
    
    /// Get groups with entries
    /// - Returns: Array of groups that have entries
    func groupsWithEntries() -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.filter { ($0.entries?.count ?? 0) > 0 }
    }
    

    
    /// Get groups with categories
    /// - Returns: Array of groups that have categories
    func groupsWithCategories() -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.filter { ($0.categories?.count ?? 0) > 0 }
    }
    

    
    /// Get groups with members
    /// - Returns: Array of groups that have members
    func groupsWithMembers() -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.filter { group in
            guard let userGroups = group.userGroups else { return false }
            return userGroups.count > 0
        }
    }
    

    
    /// Get groups by currency
    /// - Parameter currency: The currency to filter by
    /// - Returns: Array of groups using the specified currency
    func groups(withCurrency currency: String) -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.filter { group in
            guard let groupCurrency = group.currency else { return false }
            return groupCurrency == currency
        }
    }
    

    
    /// Calculate total amount across all groups
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmountAcrossAllGroups() -> NSDecimalNumber {
        // This is a heavy calculation, should be done in background
        // For now, return a simple calculation, but in production this should be cached
        return groups.reduce(NSDecimalNumber.zero) { total, group in
            let groupEntries = group.entries ?? NSSet()
            let groupTotal = groupEntries.reduce(NSDecimalNumber.zero) { entryTotal, entry in
                guard let entry = entry as? Entry else { return entryTotal }
                let entryItems = entry.items ?? NSSet()
                let entryAmount = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                    guard let item = item as? Item else { return itemTotal }
                    let itemAmount = item.amount ?? NSDecimalNumber.zero
                    return itemTotal.safeAdd(itemAmount)
                }
                return entryTotal.safeAdd(entryAmount)
            }
            return total.safeAdd(groupTotal)
        }
    }
    

    
    /// Get groups sorted by total amount (highest first)
    /// - Returns: Array of groups sorted by total amount
    func groupsSortedByAmount() -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.sorted { group1, group2 in
            let group1Total = calculateGroupTotal(group1)
            let group2Total = calculateGroupTotal(group2)
            return group1Total.compare(group2Total) == .orderedDescending
        }
    }
    

    
    /// Helper method to calculate total amount for a group
    private func calculateGroupTotal(_ group: Group) -> NSDecimalNumber {
        let groupEntries = group.entries ?? NSSet()
        return groupEntries.reduce(NSDecimalNumber.zero) { entryTotal, entry in
            guard let entry = entry as? Entry else { return entryTotal }
            let entryItems = entry.items ?? NSSet()
            let entryAmount = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                guard let item = item as? Item else { return itemTotal }
                let itemAmount = item.amount ?? NSDecimalNumber.zero
                return itemTotal.safeAdd(itemAmount)
            }
            return entryTotal.safeAdd(entryAmount)
        }
    }
    
    /// Get groups sorted by entry count (highest first)
    /// - Returns: Array of groups sorted by entry count
    func groupsSortedByEntryCount() -> [Group] {
        // This is a heavy calculation, should be done in background
        return groups.sorted { group1, group2 in
            let group1EntryCount = group1.entries?.count ?? 0
            let group2EntryCount = group2.entries?.count ?? 0
            return group1EntryCount > group2EntryCount
        }
    }
    

    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
