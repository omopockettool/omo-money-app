import CoreData
import Foundation

/// ViewModel for Entry detail functionality
/// Handles entry detail display and item management
@MainActor
class EntryDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var entry: Entry?
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let entryService: EntryService
    private let itemService: ItemService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.entryService = EntryService(context: context)
        self.itemService = ItemService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load entry details
    func loadEntry(by id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            entry = try await entryService.fetchEntry(by: id)
            if let entry = entry {
                await loadItems(for: entry)
            }
        } catch {
            errorMessage = "Error loading entry: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items for a specific entry
    func loadItems(for entry: Entry) async {
        do {
            items = try await itemService.getItems(for: entry)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
    }
    
    /// Update the entry
    func updateEntry(description: String? = nil, date: Date? = nil, category: Category) async -> Bool {
        guard let entry = entry else { return false }
        
        isLoading = true
        errorMessage = nil
        
        guard let categoryId = category.id else {
            errorMessage = "Invalid category ID"
            isLoading = false
            return false
        }
        
        do {
            try await entryService.updateEntry(entry, description: description, date: date, categoryId: categoryId)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete the entry
    func deleteEntry() async -> Bool {
        guard let entry = entry else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await entryService.deleteEntry(entry)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Create a new item for the entry
    func createItem(description: String, amount: NSDecimalNumber, quantity: Int32 = 1) async -> Bool {
        guard let entry = entry else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newItem = try await itemService.createItem(description: description, amount: amount, quantity: quantity, entry: entry)
            items.append(newItem)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete an item
    func deleteItem(_ item: Item) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await itemService.deleteItem(item)
            items.removeAll { $0.id == item.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Calculate total amount for the entry
    func calculateTotalAmount() async -> NSDecimalNumber {
        guard let entry = entry else { return NSDecimalNumber.zero }
        
        do {
            return try await itemService.calculateTotalAmount(for: entry)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    /// Get items count
    func getItemsCount() async -> Int {
        guard let entry = entry else { return 0 }
        
        do {
            let itemsForEntry = try await itemService.getItems(for: entry)
            return itemsForEntry.count
        } catch {
            errorMessage = "Error getting items count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
