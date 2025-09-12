import CoreData
import Foundation

/// ViewModel for ItemList detail functionality
/// Handles itemList detail display and item management
@MainActor
class ItemListDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var itemList: ItemList?
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let itemListService: ItemListService
    private let itemService: ItemService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.itemListService = ItemListService(context: context)
        self.itemService = ItemService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load item list details
    func loadItemList(by id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            itemList = try await itemListService.fetchItemList(by: id)
            if let itemList = itemList {
                await loadItems(for: itemList)
            }
        } catch {
            errorMessage = "Error loading itemList: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load items for a specific itemList
    func loadItems(for itemList: ItemList) async {
        do {
            items = try await itemService.getItems(for: itemList)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
        }
    }
    
    /// Update the itemList
    func updateItemList(description: String? = nil, date: Date? = nil, category: Category) async -> Bool {
        guard let itemList = itemList else { return false }
        
        isLoading = true
        errorMessage = nil
        
        guard let categoryId = category.id else {
            errorMessage = "Invalid category ID"
            isLoading = false
            return false
        }
        
        do {
            try await itemListService.updateItemList(itemList, description: description, date: date, categoryId: categoryId)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating itemList: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete the itemList
    func deleteItemList() async -> Bool {
        guard let itemList = itemList else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await itemListService.deleteItemList(itemList)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting itemList: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Create a new item for the itemList
    func createItem(description: String, amount: NSDecimalNumber, quantity: Int32 = 1) async -> Bool {
        guard let itemList = itemList else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newItem = try await itemService.createItem(description: description, amount: amount, quantity: quantity, itemList: itemList)
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
    
    /// Calculate total amount for the itemList
    func calculateTotalAmount() async -> NSDecimalNumber {
        guard let itemList = itemList else { return NSDecimalNumber.zero }
        
        do {
            return try await itemService.calculateTotalAmount(for: itemList)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    /// Get items count
    func getItemsCount() async -> Int {
        guard let itemList = itemList else { return 0 }
        
        do {
            let itemsForItemList = try await itemService.getItems(for: itemList)
            return itemsForItemList.count
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
