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
    
    private let context: NSManagedObjectContext
    
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
        
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
        
        do {
            entries = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch entries: \(error.localizedDescription)"
            print("Error fetching entries: \(error)")
        }
        
        isLoading = false
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
        
        let newEntry = Entry(context: context, description: description, date: date, category: category, group: group)
        
        do {
            try context.save()
            fetchEntries() // Refresh the list
            isLoading = false
            return newEntry
        } catch {
            context.rollback()
            errorMessage = "Failed to create entry: \(error.localizedDescription)"
            print("Error creating entry: \(error)")
            isLoading = false
            return nil
        }
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
        
        if let description = description {
            entry.entryDescription = description
        }
        
        if let date = date {
            entry.date = date
        }
        
        if let category = category {
            entry.category = category
        }
        
        entry.updateTimestamp()
        
        do {
            try context.save()
            fetchEntries() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update entry: \(error.localizedDescription)"
            print("Error updating entry: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete an entry
    /// - Parameter entry: The entry to delete
    /// - Returns: True if deletion was successful
    func deleteEntry(_ entry: Entry) -> Bool {
        isLoading = true
        errorMessage = nil
        
        context.delete(entry)
        
        do {
            try context.save()
            fetchEntries() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
            print("Error deleting entry: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get entries for a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of entries in the group
    func entries(for group: Group) -> [Entry] {
        return entries.filter { $0.group?.id == group.id }
    }
    
    /// Get entries for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of entries in the category
    func entries(for category: Category) -> [Entry] {
        return entries.filter { $0.category?.id == category.id }
    }
    
    /// Get entries for a specific date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of entries in the date range
    func entries(from startDate: Date, to endDate: Date) -> [Entry] {
        return entries.filter { entry in
            entry.date >= startDate && entry.date <= endDate
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
            let entryMonth = calendar.component(.month, from: entry.date)
            let entryYear = calendar.component(.year, from: entry.date)
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
            total.adding(entry.totalAmount)
        }
    }
    
    /// Calculate total amount for a specific category
    /// - Parameter category: The category to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for category: Category) -> NSDecimalNumber {
        let categoryEntries = entries(for: category)
        return categoryEntries.reduce(NSDecimalNumber.zero) { total, entry in
            total.adding(entry.totalAmount)
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
            total.adding(entry.totalAmount)
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
