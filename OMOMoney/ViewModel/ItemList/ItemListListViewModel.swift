import CoreData
import Foundation

/// ViewModel for ItemList list functionality
/// Handles itemList list display and management
@MainActor
class ItemListListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var itemLists: [ItemList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let itemListService: ItemListService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.itemListService = ItemListService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all itemLists
    func loadItemLists() async {
        isLoading = true
        errorMessage = nil
        
        do {
            itemLists = try await itemListService.fetchItemLists()
        } catch {
            errorMessage = "Error loading itemLists: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load itemLists for a specific group
    func loadItemLists(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            itemLists = try await itemListService.getItemLists(for: group)
        } catch {
            errorMessage = "Error loading itemLists: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load itemLists for a specific category
    func loadItemLists(for category: Category) async {
        isLoading = true
        errorMessage = nil
        
        do {
            itemLists = try await itemListService.getItemLists(for: category)
        } catch {
            errorMessage = "Error loading itemLists: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load itemLists within a date range
    func loadItemLists(from startDate: Date, to endDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            itemLists = try await itemListService.getItemLists(from: startDate, to: endDate)
        } catch {
            errorMessage = "Error loading itemLists: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new itemList
    func createItemList(description: String, date: Date, group: Group, category: Category) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let categoryId = category.id, let groupId = group.id else {
                errorMessage = "Invalid category or group ID"
                isLoading = false
                return false
            }
            
            let newItemList = try await itemListService.createItemList(
                description: description, 
                date: date, 
                categoryId: categoryId, 
                groupId: groupId
            )
            itemLists.insert(newItemList, at: 0) // Add at beginning since itemLists are sorted by date desc
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating itemList: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete an itemList
    func deleteItemList(_ itemList: ItemList) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await itemListService.deleteItemList(itemList)
            itemLists.removeAll { $0.id == itemList.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting itemList: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // Note: For itemLists count, use getItemListsCount(for group: Group) or getItemListsCount(for user: User)
    // to ensure proper filtering by user context
    
    /// Get itemLists count for a specific group
    func getItemListsCount(for group: Group) async -> Int {
        do {
            return try await itemListService.getItemListsCount(for: group)
        } catch {
            errorMessage = "Error getting itemLists count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
