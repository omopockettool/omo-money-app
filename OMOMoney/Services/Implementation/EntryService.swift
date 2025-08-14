import Foundation
import CoreData

/// Service class for Entry entity operations
/// Handles all CRUD operations for Entry with proper threading
class EntryService: CoreDataService, EntryServiceProtocol {
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Entry CRUD Operations
    
    /// Fetch all entries
    func fetchEntries() async throws -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        return try await fetch(request)
    }
    
    /// Fetch entry by ID
    func fetchEntry(by id: UUID) async throws -> Entry? {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new entry
    func createEntry(description: String?, date: Date, categoryId: UUID, groupId: UUID) async throws -> Entry {
        try await context.perform {
            let entry = Entry(context: self.context)
            entry.id = UUID()
            entry.entryDescription = description
            entry.date = date
            entry.createdAt = Date()
            
            // Set group by ID
            if let group = try? self.context.fetch(NSFetchRequest<Group>(entityName: "Group")).first(where: { $0.id == groupId }) {
                entry.group = group
            }
            
            // Set category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                entry.category = category
            }
            
            try self.context.save()
            return entry
        }
    }
    
    /// Update an existing entry
    func updateEntry(_ entry: Entry, description: String? = nil, date: Date? = nil, categoryId: UUID) async throws {
        try await context.perform {
            if let description = description {
                entry.entryDescription = description
            }
            if let date = date {
                entry.date = date
            }
            
            // Update category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                entry.category = category
            }
            
            entry.lastModifiedAt = Date()
            
            try self.context.save()
        }
    }
    
    /// Delete an entry
    func deleteEntry(_ entry: Entry) async throws {
        await delete(entry)
        try await save()
    }
    
    /// Get entries for a specific group
    func getEntries(for group: Group) async throws -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
        return try await fetch(request)
    }
    
    /// Get entries for a specific category
    func getEntries(for category: Category) async throws -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
        return try await fetch(request)
    }
    
    /// Get entries within a date range
    func getEntries(from startDate: Date, to endDate: Date) async throws -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
        return try await fetch(request)
    }
    
    /// Get entries count
    func getEntriesCount() async throws -> Int {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        return try await count(request)
    }
    
    /// Get entries count for a specific group
    func getEntriesCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
}
