import CoreData
import Foundation

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
    

    
    /// Load items for a specific itemList
    func loadItems(for itemList: ItemList) async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await itemService.getItems(for: itemList)
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
    
    /// Create a new item
    func createItem(description: String, amount: NSDecimalNumber, quantity: Int32 = 1, itemList: ItemList) async -> Bool {
        isLoading = true
        errorMessage = nil

        guard let itemListId = itemList.id else {
            errorMessage = "Error: ItemList has no ID"
            isLoading = false
            return false
        }

        do {
            let newItem = try await itemService.createItem(description: description, amount: amount, quantity: quantity, itemListId: itemListId)
            items.append(newItem)
            items.sort { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String? = nil, amount: NSDecimalNumber? = nil, quantity: Int32? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await itemService.updateItem(item, description: description, amount: amount, quantity: quantity)
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
            return try await itemService.calculateTotalAmount(for: items.first?.itemList?.group ?? Group())
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    // Note: For items count, use itemService.getItems(for: itemList) and then .count
    // to ensure proper filtering by itemList context
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
