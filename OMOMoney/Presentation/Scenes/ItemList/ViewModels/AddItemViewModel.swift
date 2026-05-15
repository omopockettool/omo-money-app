//
//  AddItemViewModel.swift
//  OMOMoney
//

import Foundation

@MainActor

@Observable
final class AddItemViewModel {

    // MARK: - Published Properties
    var description = ""
    var amount = ""
    var quantity = "1"
    var isSaving = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies
    private let itemListId: UUID
    private let itemToEdit: SDItem?
    private let itemListDescription: String
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase

    // MARK: - Computed Properties
    var isEditMode: Bool { itemToEdit != nil }

    var canSave: Bool {
        let hasDescription = !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (hasDescription || hasAmount) && isQuantityValid && isAmountValid && !isSaving
    }

    var showsTotalPreview: Bool {
        let normalized = amount.replacingOccurrences(of: ",", with: ".")
        guard let price = Decimal(string: normalized), price > 0,
              let qty = Int(quantity), qty > 1 else { return false }
        return true
    }

    private var isQuantityValid: Bool {
        guard let quantityInt = Int(quantity) else { return false }
        return quantityInt > 0
    }

    private var isAmountValid: Bool {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAmount.isEmpty else { return true }

        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")
        if normalizedAmount.hasSuffix(".") { return false }
        return Decimal(string: normalizedAmount) != nil
    }

    // MARK: - Initialization
    init(
        itemListId: UUID,
        itemToEdit: SDItem? = nil,
        itemListDescription: String,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.itemListId = itemListId
        self.itemToEdit = itemToEdit
        self.itemListDescription = itemListDescription
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase

        if let item = itemToEdit {
            self.description = item.itemDescription
            self.amount = item.amount == 0 ? "" : String(format: "%.2f", item.amount).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            self.quantity = String(item.quantity)
        }
    }

    // MARK: - Public Methods

    func saveItem() async -> SDItem? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmed.isEmpty ? itemListDescription : trimmed

        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")

        if !trimmedAmount.isEmpty, normalizedAmount.hasSuffix(".") {
            errorMessage = "Cantidad inválida"
            showError = true
            return nil
        }

        guard let amountDecimal = normalizedAmount.isEmpty ? Decimal(0) : Decimal(string: normalizedAmount) else {
            errorMessage = "Cantidad inválida"
            showError = true
            return nil
        }

        guard let quantityInt = Int32(quantity), quantityInt > 0 else {
            errorMessage = "Unidades inválidas"
            showError = true
            return nil
        }

        isSaving = true
        errorMessage = nil
        showError = false

        do {
            let item: SDItem

            if let existingItem = itemToEdit {
                // Edit mode — mutate SD* reference type directly
                existingItem.itemDescription = finalDescription
                existingItem.amount = Double(truncating: NSDecimalNumber(decimal: amountDecimal))
                existingItem.quantity = Int(quantityInt)
                try await updateItemUseCase.execute(existingItem)
                item = existingItem
            } else {
                // Items created from the detail view start unpaid by default.
                // Quick-add from the dashboard uses a different flow.
                item = try await createItemUseCase.execute(
                    description: finalDescription,
                    amount: amountDecimal,
                    quantity: quantityInt,
                    itemListId: itemListId,
                    isPaid: false
                )
            }

            isSaving = false
            return item
        } catch {
            errorMessage = "Error al guardar artículo: \(error.localizedDescription)"
            showError = true
            isSaving = false
            return nil
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func validateAndCorrectAmount() {
        amount = correctAmountInput(amount)
    }

    func sanitizeQuantityInput(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        guard let number = Int(digits) else { return digits }
        return String(min(max(number, 1), 999999))
    }

    // MARK: - Private Methods

    private func correctAmountInput(_ input: String) -> String {
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

        if integerPart.count > 10 {
            integerPart = String(integerPart.prefix(10))
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
}
