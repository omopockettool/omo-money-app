
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
    private let updateItemListUseCase: UpdateItemListUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let itemListToEdit: ItemListDomain?

    // MARK: - Computed

    var isEditMode: Bool { itemListToEdit != nil }

    // MARK: - Initialization

    init(
        itemListToEdit: ItemListDomain? = nil,
        createItemListUseCase: CreateItemListUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemListUseCase: UpdateItemListUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    ) {
        self.itemListToEdit = itemListToEdit
        self.createItemListUseCase = createItemListUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemListUseCase = updateItemListUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase

        // Pre-populate fields when editing
        if let toEdit = itemListToEdit {
            self.description = toEdit.itemListDescription
            self.date = toEdit.date
        }
    }

    /// Convenience initializer using DI Container
    convenience init(itemListToEdit: ItemListDomain? = nil, initialDate: Date? = nil) {
        let appContainer = AppDIContainer.shared
        self.init(
            itemListToEdit: itemListToEdit,
            createItemListUseCase: appContainer.makeCreateItemListUseCase(),
            createItemUseCase: appContainer.makeCreateItemUseCase(),
            updateItemListUseCase: appContainer.makeUpdateItemListUseCase(),
            fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase(),
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase()
        )
        if itemListToEdit == nil, let initialDate {
            self.date = initialDate
        }
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }

    /// Check if the form can be saved
    var canSave: Bool {
        selectedCategory != nil &&
        selectedPaymentMethod != nil &&
        isPriceValid
    }

    /// Check if price is valid (empty or valid decimal)
    var isPriceValid: Bool {
        if price.isEmpty { return true }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        // Allow trailing decimal separator — user is still typing (e.g. "123.")
        if normalizedPrice.hasSuffix(".") { return true }
        return NSDecimalNumber(string: normalizedPrice) != NSDecimalNumber.notANumber
    }

    /// Get price as Decimal, returns nil if empty or invalid
    var priceAsDecimal: Decimal? {
        guard !price.isEmpty else { return nil }

        // ✅ FIX: Normalize comma to period for European decimal format (3,58 → 3.58)
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")

        guard let decimal = Decimal(string: normalizedPrice) else { return nil }
        return decimal
    }

    // MARK: - Public Methods

    /// Load categories for the specified group
    /// ✅ Clean Architecture: Accept UUID, use Use Case to fetch Domain models
    func loadCategories(forGroupId groupId: UUID, lastUsedCategoryId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            if isEditMode {
                // Pre-select the existing category when editing
                selectedCategory = categories.first { $0.id == itemListToEdit?.categoryId }
            } else {
                // Pre-select last used only — nil if first time (forces conscious choice)
                selectedCategory = lastUsedCategoryId.flatMap { id in
                    categories.first { $0.id == id }
                }
            }
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load active payment methods for the specified group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case instead of Service
    func loadPaymentMethods(forGroupId groupId: UUID, lastUsedPaymentMethodId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            if isEditMode {
                // Pre-select the existing payment method when editing
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethodId }
            } else {
                // Pre-select last used only — nil if first time (forces conscious choice)
                selectedPaymentMethod = lastUsedPaymentMethodId.flatMap { id in
                    paymentMethods.first { $0.id == id }
                }
            }
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

            // Step 1: Create ItemList
            let itemList = try await createItemListUseCase.execute(
                description: trimmedDescription,
                date: date,
                categoryId: categoryId,
                paymentMethodId: paymentMethodId,
                groupId: groupId
            )

            // Step 2: If price provided, create automatic Item (marked paid if amount > 0)
            if let priceDecimal = priceAsDecimal {
                let _ = try await createItemUseCase.execute(
                    description: trimmedDescription,
                    amount: priceDecimal,
                    quantity: 1,
                    itemListId: itemList.id,
                    isPaid: priceDecimal > 0
                )
            }

            isLoading = false
            return itemList
        } catch {
            errorMessage = "Error al crear gasto: \(error.localizedDescription)"
            print("❌ AddItemListViewModel: Error creating ItemList/Item: \(error.localizedDescription)")
            isLoading = false
            return nil
        }
    }

    /// Update the existing itemList with current form values
    /// Returns the updated ItemListDomain if successful, nil otherwise
    func updateItemList(groupId: UUID) async -> ItemListDomain? {
        guard let toEdit = itemListToEdit,
              let category = selectedCategory else { return nil }
        isLoading = true
        errorMessage = nil

        let updated = ItemListDomain(
            id: toEdit.id,
            itemListDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            categoryId: category.id,
            paymentMethodId: selectedPaymentMethod?.id,
            groupId: toEdit.groupId,
            createdAt: toEdit.createdAt,
            lastModifiedAt: Date()
        )

        do {
            try await updateItemListUseCase.execute(updated)
            isLoading = false
            return updated
        } catch {
            errorMessage = "Error al actualizar: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    /// Validate and correct price input
    /// - Maximum 7 digits before decimal (9 total including 2 decimals)
    /// - Maximum 2 decimal places
    /// - Allows both comma and period as decimal separator
    func validateAndCorrectPrice() {
        price = correctPriceInput(price)
    }

    // MARK: - Private Methods

    /// Correct price input to meet constraints
    /// - Maximum 7 digits before decimal (9 total including 2 decimals, e.g. 1234567.89)
    /// - Maximum 2 decimal places
    /// - Allows both comma and period as decimal separator
    private func correctPriceInput(_ input: String) -> String {
        // Allow empty string
        if input.isEmpty {
            return input
        }

        // Filter: only allow digits, comma, and period
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var filtered = input.filter { char in
            return char.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        }

        // Normalize: replace comma with period for consistent handling
        filtered = filtered.replacingOccurrences(of: ",", with: ".")

        // Handle multiple decimal separators - keep only the first one
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            filtered = components[0] + "." + components[1...].joined()
        }

        // Split into integer and decimal parts
        let parts = filtered.components(separatedBy: ".")
        var integerPart = parts[0]
        var decimalPart = parts.count > 1 ? parts[1] : ""

        // Limit integer part to 7 digits (9 total including 2 decimals)
        if integerPart.count > 7 {
            integerPart = String(integerPart.prefix(7))
        }

        // Limit decimal part to 2 digits
        if decimalPart.count > 2 {
            decimalPart = String(decimalPart.prefix(2))
        }

        // Reconstruct the string
        if parts.count > 1 {
            return integerPart + "." + decimalPart
        } else {
            return integerPart
        }
    }

    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
