import Foundation
import CoreData

/// ViewModel for Item list functionality
/// Handles item list display and management
@MainActor
class ItemListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let itemService: ItemService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.itemService = ItemService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all items
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.fetchItems()
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items for a specific entry
    func loadItems(for entry: Entry) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.getItems(for: entry)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items for a specific category
    func loadItems(for category: Category) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.getItems(for: category)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items for a specific group
    func loadItems(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.getItems(for: group)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items with amount greater than specified value
    func loadItems(withAmountGreaterThan amount: NSDecimalNumber) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.getItems(withAmountGreaterThan: amount)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new item
    func createItem(description: String, amount: NSDecimalNumber, entry: Entry) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newItem = try await itemService.createItem(description: description, amount: amount, entry: entry)
            items.append(newItem)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String? = nil, amount: NSDecimalNumber? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await itemService.updateItem(item, description: description, amount: amount)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating item: \(error.localizedDescription)"
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
    
    /// Calculate total amount for all items
    func calculateTotalAmount() async -> NSDecimalNumber {
        do {
            return try await itemService.calculateTotalAmount(for: items.first?.entry?.group ?? Group())
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    /// Get items count
    func getItemsCount() async -> Int {
        do {
            return try await itemService.getItemsCount()
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
