
import Foundation
import UIKit

@MainActor

@Observable
final class AddItemListViewModel {

    // MARK: - Published Properties
    var categories: [SDCategory] = []
    var paymentMethods: [SDPaymentMethod] = []
    var isLoading = false
    var errorMessage: String?
    var toast: ToastMessage?
    var description = ""
    var price = ""
    var date = Date()
    var selectedCategory: SDCategory?
    var selectedPaymentMethod: SDPaymentMethod?
    var suggestions: [String] = []
    var lastUsedConcept: String?

    // MARK: - Dependencies
    private let createItemListUseCase: CreateItemListUseCase
    private let createItemUseCase: CreateItemUseCase
    private let updateItemListUseCase: UpdateItemListUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let itemListToEdit: SDItemList?

    // MARK: - Computed

    var isEditMode: Bool { itemListToEdit != nil }

    // MARK: - Initialization

    init(
        itemListToEdit: SDItemList? = nil,
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

        if let toEdit = itemListToEdit {
            self.description = toEdit.itemListDescription
            self.date = toEdit.date
        }
    }

    convenience init(itemListToEdit: SDItemList? = nil, initialDate: Date? = nil) {
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

    var formattedDate: String { DateFormatterHelper.formatDate(date) }

    var canSave: Bool {
        isPriceValid
    }

    var isPriceValid: Bool {
        if price.isEmpty { return true }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        if normalizedPrice.hasSuffix(".") { return true }
        return NSDecimalNumber(string: normalizedPrice) != NSDecimalNumber.notANumber
    }

    var priceAsDecimal: Decimal? {
        guard !price.isEmpty else { return nil }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: normalizedPrice) else { return nil }
        return decimal
    }

    func showValidationToast() {
        if !isPriceValid {
            toast = ToastMessage("Precio no válido", type: .warning)
        }
    }

    // MARK: - Public Methods

    func loadCategories(forGroupId groupId: UUID, lastUsedCategoryId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            if isEditMode {
                selectedCategory = categories.first { $0.id == itemListToEdit?.category?.id }
            } else {
                selectedCategory = lastUsedCategoryId.flatMap { id in
                    categories.first { $0.id == id }
                }
            }
            updateSuggestions()
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadPaymentMethods(forGroupId groupId: UUID, lastUsedPaymentMethodId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            if isEditMode {
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethod?.id }
            }
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID,
        groupId: UUID,
        paymentMethodId: UUID?
    ) async -> SDItemList? {
        isLoading = true
        errorMessage = nil

        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

            let itemList = try await createItemListUseCase.execute(
                description: trimmedDescription,
                date: date,
                categoryId: categoryId,
                paymentMethodId: paymentMethodId,
                groupId: groupId
            )

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

    func updateItemList(groupId: UUID) async -> SDItemList? {
        guard let toEdit = itemListToEdit else { return nil }
        isLoading = true
        errorMessage = nil

        if let newCategory = selectedCategory,
           newCategory.id != toEdit.category?.id,
           let oldCategoryName = toEdit.category?.name,
           toEdit.items.count == 1,
           let item = toEdit.items.first,
           toEdit.itemListDescription == oldCategoryName,
           item.itemDescription == oldCategoryName {
            description = newCategory.name
            item.itemDescription = newCategory.name
        }

        let newDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldDescription = toEdit.itemListDescription

        // If the item list has exactly one item whose name matches the old list name,
        // keep them in sync when the user renames the list.
        if newDescription != oldDescription,
           toEdit.items.count == 1,
           let singleItem = toEdit.items.first,
           singleItem.itemDescription == oldDescription {
            singleItem.itemDescription = newDescription
        }

        toEdit.itemListDescription = newDescription
        toEdit.date = date
        if let category = selectedCategory { toEdit.category = category }
        toEdit.paymentMethod = selectedPaymentMethod

        do {
            try await updateItemListUseCase.execute(toEdit)
            isLoading = false
            return toEdit
        } catch {
            errorMessage = "Error al actualizar: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    func validateAndCorrectPrice() {
        price = correctPriceInput(price)
    }

    func pastePrice() {
        guard let raw = UIPasteboard.general.string else { return }
        price = correctPriceInput(raw)
    }

    // MARK: - Private Methods

    private func correctPriceInput(_ input: String) -> String {
        if input.isEmpty { return input }

        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var filtered = input.filter { char in
            return char.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        }

        filtered = filtered.replacingOccurrences(of: ",", with: ".")

        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            filtered = components[0] + "." + components[1...].joined()
        }

        let parts = filtered.components(separatedBy: ".")
        var integerPart = parts[0]
        var decimalPart = parts.count > 1 ? parts[1] : ""

        if integerPart.count > 7 {
            integerPart = String(integerPart.prefix(7))
        }

        if decimalPart.count > 2 {
            decimalPart = String(decimalPart.prefix(2))
        }

        if parts.count > 1 {
            return integerPart + "." + decimalPart
        } else {
            return integerPart
        }
    }

    func updateSuggestions() {
        suggestions = ConceptSuggestionEngine.getSuggestions(
            query: description,
            amount: priceAsDecimal.map { Double(truncating: $0 as NSDecimalNumber) },
            forCategory: selectedCategory,
            allCategories: categories
        )
        lastUsedConcept = ConceptSuggestionEngine.lastUsed(forCategory: selectedCategory)
    }

    func clearError() {
        errorMessage = nil
    }
}
