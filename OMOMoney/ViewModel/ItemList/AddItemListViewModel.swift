import Foundation
import CoreData

@MainActor
final class AddItemListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var description = ""
    @Published var date = Date()
    @Published var selectedCategory: Category?
    @Published var selectedPaymentMethod: PaymentMethod?
    
    // MARK: - Dependencies
    private let itemListService: ItemListServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let itemService: ItemServiceProtocol
    private let paymentMethodService: PaymentMethodServiceProtocol
    // MARK: - Initialization
    
    init(
        itemListService: ItemListServiceProtocol,
        categoryService: CategoryServiceProtocol,
        itemService: ItemServiceProtocol,
        paymentMethodService: PaymentMethodServiceProtocol
    ) {
        self.itemListService = itemListService
        self.categoryService = categoryService
        self.itemService = itemService
        self.paymentMethodService = paymentMethodService
        
        print("🔄 AddItemListViewModel: Initialized")
    }
    
    // MARK: - Computed Properties
    
    /// Check if the form can be saved
    var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        selectedPaymentMethod != nil
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
    
    /// Load active payment methods for the specified group
    func loadPaymentMethods(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            paymentMethods = try await paymentMethodService.getActivePaymentMethods(for: group)
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new itemList with the specified details
    func createItemList(
        description: String,
        date: Date,
        category: Category,
        group: Group,
        paymentMethod: PaymentMethod?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 AddItemListViewModel: Creating ItemList...")
            let itemList = try await itemListService.createItemList(
                description: description,
                date: date,
                categoryId: category.id ?? UUID(),
                groupId: group.id ?? UUID(),
                paymentMethodId: paymentMethod?.id
            )
            
            print("✅ AddItemListViewModel: ItemList created successfully: \(itemList.itemListDescription ?? "No description")")
            print("✅ AddItemListViewModel: ItemList creation completed, callback will handle refresh")
            
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
