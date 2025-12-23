//
//  AddItemViewModel.swift
//  OMOMoney
//
//  Created on 12/2/24.
//

import Foundation
import CoreData

@MainActor
final class AddItemViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var description = ""
    @Published var amount = ""
    @Published var quantity = "1"
    @Published var isSaving = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let itemListId: UUID
    private let itemToEdit: ItemDomain?
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase

    // MARK: - Computed Properties
    var isEditMode: Bool { itemToEdit != nil }

    var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        !quantity.isEmpty &&
        !isSaving
    }

    // MARK: - Initialization
    init(
        itemListId: UUID,
        itemToEdit: ItemDomain? = nil,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.itemListId = itemListId
        self.itemToEdit = itemToEdit
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase

        // Pre-populate fields if editing
        if let item = itemToEdit {
            self.description = item.itemDescription
            self.amount = item.amount.description
            self.quantity = String(item.quantity)
        }
    }

    // MARK: - Public Methods

    /// Save the item (create or update)
    /// Returns ItemDomain for incremental cache update (following ItemList pattern)
    func saveItem() async -> ItemDomain? {
        // Normalize: replace comma with period for decimal parsing
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")

        guard let amountDecimal = Decimal(string: normalizedAmount),
              let quantityInt = Int32(quantity) else {
            errorMessage = "Cantidad o unidades inválidas"
            return nil
        }

        isSaving = true
        errorMessage = nil

        do {
            let itemDomain: ItemDomain

            if let existingItem = itemToEdit {
                // Edit mode - use Update Use Case
                let updatedItemDomain = ItemDomain(
                    id: existingItem.id,
                    itemDescription: description,
                    amount: amountDecimal,
                    quantity: quantityInt,
                    itemListId: itemListId,
                    createdAt: existingItem.createdAt,
                    lastModifiedAt: Date()
                )
                try await updateItemUseCase.execute(updatedItemDomain)

                // Return the domain model (Service already saved to Core Data)
                itemDomain = updatedItemDomain
                print("✅ AddItemViewModel: Item updated successfully")
            } else {
                // Create mode - use Create Use Case
                itemDomain = try await createItemUseCase.execute(
                    description: description,
                    amount: amountDecimal,
                    quantity: quantityInt,
                    itemListId: itemListId
                )
                print("✅ AddItemViewModel: Item created successfully")
            }

            print("💡 AddItemViewModel: Returning ItemDomain for incremental cache update")
            isSaving = false
            return itemDomain
        } catch {
            errorMessage = "Error al guardar item: \(error.localizedDescription)"
            print("❌ AddItemViewModel: Error saving item: \(error.localizedDescription)")
            isSaving = false
            return nil
        }
    }

    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Public Methods (Input Validation)

    /// Validate and correct amount input
    /// - Maximum 10 digits before decimal
    /// - Maximum 2 decimal places
    /// - Allows both comma and period as decimal separator
    func validateAndCorrectAmount() {
        amount = correctAmountInput(amount)
    }

    // MARK: - Private Methods

    /// Correct amount input to meet constraints
    /// - Maximum 10 digits before decimal
    /// - Maximum 2 decimal places
    /// - Allows both comma and period as decimal separator
    private func correctAmountInput(_ input: String) -> String {
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

        // Limit integer part to 10 digits
        if integerPart.count > 10 {
            integerPart = String(integerPart.prefix(10))
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
}

