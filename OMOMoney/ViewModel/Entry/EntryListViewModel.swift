import Foundation
import CoreData

/// ViewModel for Entry list functionality
/// Handles entry list display and management
@MainActor
class EntryListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var entries: [Entry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let entryService: EntryService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.entryService = EntryService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all entries
    func loadEntries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await entryService.fetchEntries()
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load entries for a specific group
    func loadEntries(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await entryService.getEntries(for: group)
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load entries for a specific category
    func loadEntries(for category: Category) async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await entryService.getEntries(for: category)
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load entries within a date range
    func loadEntries(from startDate: Date, to endDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await entryService.getEntries(from: startDate, to: endDate)
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new entry
    func createEntry(description: String, date: Date, group: Group, category: Category? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newEntry = try await entryService.createEntry(description: description, date: date, group: group, category: category)
            entries.insert(newEntry, at: 0) // Add at beginning since entries are sorted by date desc
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete an entry
    func deleteEntry(_ entry: Entry) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await entryService.deleteEntry(entry)
            entries.removeAll { $0.id == entry.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Get entries count
    func getEntriesCount() async -> Int {
        do {
            return try await entryService.getEntriesCount()
        } catch {
            errorMessage = "Error getting entries count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Get entries count for a specific group
    func getEntriesCount(for group: Group) async -> Int {
        do {
            return try await entryService.getEntriesCount(for: group)
        } catch {
            errorMessage = "Error getting entries count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
