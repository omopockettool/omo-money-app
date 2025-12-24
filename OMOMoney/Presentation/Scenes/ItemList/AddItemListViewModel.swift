
import Foundation

/// ✅ Clean Architecture: ViewModel works with Domain models only
@MainActor
final class AddItemListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // ✅ Clean Architecture: Use Domain models, not Core Data entities
    @Published var categories: [CategoryDomain] = []
    @Published var paymentMethods: [PaymentMethodDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var description = ""
    @Published var price = ""  // Optional price field - empty means no automatic item
    @Published var date = Date()
    @Published var selectedCategory: CategoryDomain?
    @Published var selectedPaymentMethod: PaymentMethodDomain?

    // MARK: - Dependencies
    private let createItemListUseCase: CreateItemListUseCase
    private let createItemUseCase: CreateItemUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase

    // MARK: - Initialization

    init(
        createItemListUseCase: CreateItemListUseCase,
        createItemUseCase: CreateItemUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    ) {
        self.createItemListUseCase = createItemListUseCase
        self.createItemUseCase = createItemUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        print("🔄 AddItemListViewModel: Initialized")
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createItemListUseCase: appContainer.makeCreateItemListUseCase(),
            createItemUseCase: appContainer.makeCreateItemUseCase(),
            fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase(),
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase()
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
    /// ✅ Clean Architecture: Accept UUID, use Use Case to fetch Domain models
    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }

        isLoading = false
    }
    
    /// Load active payment methods for the specified group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case instead of Service
    func loadPaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
        }

        isLoading = false
    }
    
    /// Create a new itemList with the specified details
    /// If price is provided, also creates an automatic Item
    /// Returns the created ItemListDomain if successful, nil otherwise
    /// ✅ Clean Architecture: Accept UUIDs, work with Domain models
    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID,
        groupId: UUID,
        paymentMethodId: UUID?
    ) async -> ItemListDomain? {
        isLoading = true
        errorMessage = nil

        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

            print("🔄 AddItemListViewModel: Creating ItemList...")
            print("📝 Description: \(trimmedDescription)")
            print("💰 Price: \(price.isEmpty ? "None (ItemList only)" : price)")
            print("📂 Category ID: \(categoryId)")
            print("💳 Payment Method ID: \(paymentMethodId?.uuidString ?? "None")")

            // Step 1: Create ItemList
            let itemList = try await createItemListUseCase.execute(
                description: trimmedDescription,
                date: date,
                categoryId: categoryId,
                paymentMethodId: paymentMethodId,
                groupId: groupId
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
