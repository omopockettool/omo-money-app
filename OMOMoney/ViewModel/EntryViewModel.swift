//
//  EntryViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class EntryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of entries for SwiftUI binding
    @Published var entries: [Entry] = []
    
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
        fetchEntries()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all entries from Core Data
    func fetchEntries() {
        isLoading = true
        errorMessage = nil
        
        // Perform fetch in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
            
            do {
                let fetchedEntries = try self.context.fetch(request)
                
                // Update UI on main thread
                Task { @MainActor in
                    self.entries = fetchedEntries
                    self.isLoading = false
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to fetch entries: \(error.localizedDescription)"
                    print("Error fetching entries: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Create a new entry
    /// - Parameters:
    ///   - description: The entry description
    ///   - date: The date of the expense
    ///   - category: The category this entry belongs to
    ///   - group: The group this entry belongs to
    /// - Returns: The created entry or nil if failed
    func createEntry(description: String, date: Date, category: Category, group: Group) -> Entry? {
        isLoading = true
        errorMessage = nil
        
        // Store IDs for background operation
        guard let categoryId = category.id, let groupId = group.id else { return nil }
        
        // Perform creation in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch category and group in background context
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            
            do {
                let backgroundCategory = try self.context.fetch(categoryRequest).first
                let backgroundGroup = try self.context.fetch(groupRequest).first
                
                if let backgroundCategory = backgroundCategory, let backgroundGroup = backgroundGroup {
                    let newEntry = Entry(context: self.context)
                    newEntry.id = UUID()
                    newEntry.entryDescription = description
                    newEntry.date = date
                    newEntry.createdAt = Date()
                    newEntry.lastModifiedAt = Date()
                    newEntry.category = backgroundCategory
                    newEntry.group = backgroundGroup
                    
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchEntries()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to create entry: \(error.localizedDescription)"
                    print("Error creating entry: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return nil // Will be updated via async callback
    }
    
    /// Update an existing entry
    /// - Parameters:
    ///   - entry: The entry to update
    ///   - description: New description (optional)
    ///   - date: New date (optional)
    ///   - category: New category (optional)
    /// - Returns: True if update was successful
    func updateEntry(_ entry: Entry, description: String? = nil, date: Date? = nil, category: Category? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Store entry ID for background operation
        guard let entryId = entry.id else { return false }
        
        // Store category ID if provided
        let categoryId = category?.id
        
        // Perform update in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch entry in background context
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
            
            do {
                let backgroundEntry = try self.context.fetch(request).first
                if let backgroundEntry = backgroundEntry {
                    if let description = description {
                        backgroundEntry.entryDescription = description
                    }
                    
                    if let date = date {
                        backgroundEntry.date = date
                    }
                    
                    if let categoryId = categoryId {
                        // Fetch category in background context
                        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
                        categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
                        if let backgroundCategory = try self.context.fetch(categoryRequest).first {
                            backgroundEntry.category = backgroundCategory
                        }
                    }
                    
                    backgroundEntry.lastModifiedAt = Date()
                    
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchEntries()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to update entry: \(error.localizedDescription)"
                    print("Error updating entry: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    /// Delete an entry
    /// - Parameter entry: The entry to delete
    /// - Returns: True if deletion was successful
    func deleteEntry(_ entry: Entry) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Store entry ID for background operation
        guard let entryId = entry.id else { return false }
        
        // Perform deletion in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch entry in background context
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
            
            do {
                let backgroundEntry = try self.context.fetch(request).first
                if let backgroundEntry = backgroundEntry {
                    self.context.delete(backgroundEntry)
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchEntries()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                    print("Error deleting entry: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Utility Methods
    
    /// Get entries for a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of entries in the group
    func entries(for group: Group) -> [Entry] {
        // This is a heavy calculation, should be done in background
        return entries.filter { $0.group?.id == group.id }
    }
    
    /// Get entries for a specific group asynchronously
    /// - Parameter group: The group to filter by
    /// - Parameter completion: Callback with the filtered entries
    func entries(for group: Group, completion: @escaping ([Entry]) -> Void) {
        // Use Core Data context to perform filtering in background
        context.perform {
            guard let groupId = group.id else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
            
            do {
                let filteredEntries = try self.context.fetch(request)
                DispatchQueue.main.async {
                    completion(filteredEntries)
                }
            } catch {
                print("Error fetching entries for group: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Get entries for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of entries in the category
    func entries(for category: Category) -> [Entry] {
        // This is a heavy calculation, should be done in background
        return entries.filter { $0.category?.id == category.id }
    }
    
    /// Get entries for a specific category asynchronously
    /// - Parameter category: The category to filter by
    /// - Parameter completion: Callback with the filtered entries
    func entries(for category: Category, completion: @escaping ([Entry]) -> Void) {
        // Use Core Data context to perform filtering in background
        context.perform {
            guard let categoryId = category.id else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "category.id == %@", categoryId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
            
            do {
                let filteredEntries = try self.context.fetch(request)
                DispatchQueue.main.async {
                    completion(filteredEntries)
                }
            } catch {
                print("Error fetching entries for category: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Get entries for a specific date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of entries in the date range
    func entries(from startDate: Date, to endDate: Date) -> [Entry] {
        // This is a heavy calculation, should be done in background
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return entryDate >= startDate && entryDate <= endDate
        }
    }
    
    /// Get entries for a specific date range asynchronously
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Parameter completion: Callback with the filtered entries
    func entries(from startDate: Date, to endDate: Date, completion: @escaping ([Entry]) -> Void) {
        // Use Core Data context to perform filtering in background
        context.perform {
            let request: NSFetchRequest<Entry> = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
            
            do {
                let filteredEntries = try self.context.fetch(request)
                DispatchQueue.main.async {
                    completion(filteredEntries)
                }
            } catch {
                print("Error fetching entries for date range: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Get entries for a specific month and year
    /// - Parameters:
    ///   - month: Month (1-12)
    ///   - year: Year
    /// - Returns: Array of entries for the specified month and year
    func entries(forMonth month: Int, year: Int) -> [Entry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            let entryMonth = calendar.component(.month, from: entryDate)
            let entryYear = calendar.component(.year, from: entryDate)
            return entryMonth == month && entryYear == year
        }
    }
    
    /// Get entry by ID
    /// - Parameter id: The entry ID to search for
    /// - Returns: The entry if found, nil otherwise
    func entry(with id: UUID) -> Entry? {
        return entries.first { $0.id == id }
    }
    
    /// Calculate total amount for a specific group
    /// - Parameter group: The group to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for group: Group) -> NSDecimalNumber {
        let groupEntries = entries(for: group)
        return groupEntries.reduce(NSDecimalNumber.zero) { total, entry in
            let entryItems = entry.items ?? NSSet()
            let entryTotal = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                guard let item = item as? Item else { return itemTotal }
                let itemAmount = item.amount ?? NSDecimalNumber.zero
                return itemTotal.safeAdd(itemAmount)
            }
            return total.safeAdd(entryTotal)
        }
    }
    
    /// Calculate total amount for a specific category
    /// - Parameter category: The category to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for category: Category) -> NSDecimalNumber {
        let categoryEntries = entries(for: category)
        return categoryEntries.reduce(NSDecimalNumber.zero) { total, entry in
            let entryItems = entry.items ?? NSSet()
            let entryTotal = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                guard let item = item as? Item else { return itemTotal }
                let itemAmount = item.amount ?? NSDecimalNumber.zero
                return itemTotal.safeAdd(itemAmount)
            }
            return total.safeAdd(entryTotal)
        }
    }
    
    /// Calculate total amount for a specific month and year
    /// - Parameters:
    ///   - month: Month (1-12)
    ///   - year: Year
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(forMonth month: Int, year: Int) -> NSDecimalNumber {
        let monthEntries = entries(forMonth: month, year: year)
        return monthEntries.reduce(NSDecimalNumber.zero) { total, entry in
            let entryItems = entry.items ?? NSSet()
            let entryTotal = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                guard let item = item as? Item else { return itemTotal }
                let itemAmount = item.amount ?? NSDecimalNumber.zero
                return itemTotal.safeAdd(itemAmount)
            }
            return total.safeAdd(entryTotal)
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
