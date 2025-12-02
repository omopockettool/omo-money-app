
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
    @Published var price = ""  // Optional price field - empty means no automatic item
    @Published var date = Date()
    @Published var selectedCategory: Category?
    @Published var selectedPaymentMethod: PaymentMethod?

    // MARK: - Dependencies
    private let createItemListUseCase: CreateItemListUseCase
    private let createItemUseCase: CreateItemUseCase
    private let categoryService: CategoryServiceProtocol
    private let itemService: ItemServiceProtocol
    private let paymentMethodService: PaymentMethodServiceProtocol
    // MARK: - Initialization
    
    init(
        createItemListUseCase: CreateItemListUseCase,
        createItemUseCase: CreateItemUseCase,
        categoryService: CategoryServiceProtocol,
        itemService: ItemServiceProtocol,
        paymentMethodService: PaymentMethodServiceProtocol
    ) {
        self.createItemListUseCase = createItemListUseCase
        self.createItemUseCase = createItemUseCase
        self.categoryService = categoryService
        self.itemService = itemService
        self.paymentMethodService = paymentMethodService
        print("🔄 AddItemListViewModel: Initialized")
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createItemListUseCase: appContainer.makeCreateItemListUseCase(),
            createItemUseCase: appContainer.makeCreateItemUseCase(),
            categoryService: appContainer.categoryService,
            itemService: appContainer.itemService,
            paymentMethodService: appContainer.paymentMethodService
        )
    }
    
    // MARK: - Computed Properties

    /// Check if the form can be saved
    var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        selectedPaymentMethod != nil &&
        isPriceValid
    }

    /// Check if price is valid (empty or valid decimal)
    var isPriceValid: Bool {
        if price.isEmpty { return true }
        return NSDecimalNumber(string: price) != NSDecimalNumber.notANumber
    }

    /// Get price as Decimal, returns nil if empty or invalid
    var priceAsDecimal: Decimal? {
        guard !price.isEmpty else { return nil }
        guard let decimal = Decimal(string: price) else { return nil }
        return decimal
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
    /// If price is provided, also creates an automatic Item
    /// Returns the created ItemListDomain if successful, nil otherwise
    func createItemList(
        description: String,
        date: Date,
        category: Category,
        group: Group,
        paymentMethod: PaymentMethod?
    ) async -> ItemListDomain? {
        isLoading = true
        errorMessage = nil

        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

            print("🔄 AddItemListViewModel: Creating ItemList...")
            print("📝 Description: \(trimmedDescription)")
            print("💰 Price: \(price.isEmpty ? "None (ItemList only)" : price)")
            print("📂 Category: \(category.name ?? "Unknown")")
            print("💳 Payment Method: \(paymentMethod?.name ?? "Unknown")")

            // Step 1: Create ItemList
            let itemList = try await createItemListUseCase.execute(
                description: trimmedDescription,
                date: date,
                categoryId: category.id,
                paymentMethodId: paymentMethod?.id,
                groupId: group.id
            )

            print("✅ AddItemListViewModel: ItemList created successfully: \(itemList.itemListDescription)")

            // Step 2: If price provided, create automatic Item
            if let priceDecimal = priceAsDecimal {
                print("🔄 AddItemListViewModel: Creating automatic Item with price: \(priceDecimal)")

                let _ = try await createItemUseCase.execute(
                    description: trimmedDescription,  // Same description as ItemList
                    amount: priceDecimal,
                    quantity: 1,
                    itemListId: itemList.id
                )

                print("✅ AddItemListViewModel: Automatic Item created successfully")
            } else {
                print("ℹ️ AddItemListViewModel: No price provided, ItemList created without Items")
            }

            print("💡 AddItemListViewModel: Returning ItemListDomain for incremental cache update")
            isLoading = false
            return itemList
        } catch {
            errorMessage = "Error al crear gasto: \(error.localizedDescription)"
            print("❌ AddItemListViewModel: Error creating ItemList/Item: \(error.localizedDescription)")
            isLoading = false
            return nil
        }
    }
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
