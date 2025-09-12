import Foundation
import CoreData

@MainActor
final class AddItemListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var description = ""
    @Published var date = Date()
    @Published var selectedCategory: Category?
    
    // MARK: - Dependencies
    private let itemListService: ItemListServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let itemService: ItemServiceProtocol
    
    // MARK: - Initialization
    
    init(
        itemListService: ItemListServiceProtocol,
        categoryService: CategoryServiceProtocol,
        itemService: ItemServiceProtocol
    ) {
        self.itemListService = itemListService
        self.categoryService = categoryService
        self.itemService = itemService
    }
    
    // MARK: - Computed Properties
    
    /// Check if the form can be saved
    var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil
    }
    
    // MARK: - Public Methods
    
    /// Load categories for the specified group
    func loadCategories(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.getCategories(for: group)
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new itemList with the specified details
    func createItemList(
        description: String,
        date: Date,
        category: Category,
        group: Group
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let itemList = try await itemListService.createItemList(
                description: description,
                date: date,
                categoryId: category.id ?? UUID(),
                groupId: group.id ?? UUID()
            )
            
            // Create a default item for the itemList
            _ = try await itemService.createItem(
                description: "Item por defecto",
                amount: NSDecimalNumber(value: 0.0),
                quantity: 1,
                itemList: itemList
            )
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Error al crear itemList: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
