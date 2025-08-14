import CoreData
import Foundation

/// Protocol for Entry service operations
/// Enables dependency injection and testing
protocol EntryServiceProtocol {
    
    // MARK: - Entry CRUD Operations
    
    /// Fetch all entries
    func fetchEntries() async throws -> [Entry]
    
    /// Fetch entry by ID
    func fetchEntry(by id: UUID) async throws -> Entry?
    
    /// Create a new entry
    func createEntry(description: String?, date: Date, categoryId: UUID, groupId: UUID) async throws -> Entry
    
    /// Update an existing entry
    func updateEntry(_ entry: Entry, description: String?, date: Date?, categoryId: UUID) async throws
    
    /// Delete an entry
    func deleteEntry(_ entry: Entry) async throws
    
    /// Get entries for a specific group
    func getEntries(for group: Group) async throws -> [Entry]
    
    /// Get entries for a specific category
    func getEntries(for category: Category) async throws -> [Entry]
    
    /// Get entries within a date range
    func getEntries(from startDate: Date, to endDate: Date) async throws -> [Entry]
    
    /// Get entries count
    func getEntriesCount() async throws -> Int
}
