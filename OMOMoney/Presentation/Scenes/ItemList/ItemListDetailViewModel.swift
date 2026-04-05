//
//  ItemListDetailViewModel.swift
//  OMOMoney
//
//  Created by System on 29/11/25.
//

import Foundation
import SwiftUI

/// ✅ Clean Architecture: Works with Domain models only
@MainActor
class ItemListDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    // ✅ Clean Architecture: Store Domain models, not Core Data entities
    @Published var items: [ItemDomain] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    // MARK: - Use Cases
    private let fetchItemsUseCase: FetchItemsUseCase
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase
    private let deleteItemUseCase: DeleteItemUseCase
    private let toggleItemPaidUseCase: ToggleItemPaidUseCase

    // MARK: - Domain Model & Cache
    // ✅ Clean Architecture: Use Domain model instead of Core Data entity
    private let itemListDomain: ItemListDomain
    private let currencyCode: String
    private let cacheManager = CacheManager.shared

    // MARK: - Cache Keys
    private var serviceCacheKey: String {
        "ItemService.itemListItems.\(itemListDomain.id.uuidString)"
    }

    private var timestampKey: String {
        "\(serviceCacheKey).timestamp"
    }

    // MARK: - Initialization
    init(
        itemListDomain: ItemListDomain,
        currencyCode: String,
        fetchItemsUseCase: FetchItemsUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase,
        deleteItemUseCase: DeleteItemUseCase,
        toggleItemPaidUseCase: ToggleItemPaidUseCase
    ) {
        self.itemListDomain = itemListDomain
        self.currencyCode = currencyCode
        self.fetchItemsUseCase = fetchItemsUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase
        self.deleteItemUseCase = deleteItemUseCase
        self.toggleItemPaidUseCase = toggleItemPaidUseCase
    }

    // MARK: - Data Loading

    /// Load items for the current ItemList
    /// ✅ Clean Architecture: Uses Domain model only
    func loadItems() async {
        print("🟡 [LOAD-ITEMS] ========================================")
        print("🟡 [LOAD-ITEMS] START - Loading items for ItemList")
        print("🟡 [LOAD-ITEMS] ItemList: '\(itemListDomain.itemListDescription)'")
        print("🟡 [LOAD-ITEMS] ItemList ID: \(itemListDomain.id.uuidString)")

        // Only show loading spinner if we don't have data yet (initial load)
        // During refresh (pull-to-refresh), keep the existing list visible
        let isInitialLoad = items.isEmpty
        print("🟡 [LOAD-ITEMS] Current items count: \(items.count)")
        print("🟡 [LOAD-ITEMS] Is initial load: \(isInitialLoad)")

        if isInitialLoad {
            print("🟡 [LOAD-ITEMS] Initial load - showing spinner")
            isLoading = true
        } else {
            print("🟡 [LOAD-ITEMS] Refresh - keeping list visible")
        }
        errorMessage = nil

        do {
            print("🟡 [LOAD-ITEMS] Calling fetchItemsUseCase...")

            // ✅ Use case returns Domain models - use them directly!
            let itemDomains = try await fetchItemsUseCase.execute(forItemListId: itemListDomain.id)

            print("✅ [LOAD-ITEMS] Use Case returned \(itemDomains.count) items")
            for (index, item) in itemDomains.prefix(3).enumerated() {
                print("   \(index + 1). \(item.itemDescription) - \(item.amount)")
            }
            if itemDomains.count > 3 {
                print("   ...and \(itemDomains.count - 3) more items")
            }

            // ✅ Use Domain models directly, no Core Data conversion needed
            items = itemDomains.sorted { $0.createdAt > $1.createdAt }
            print("✅ [LOAD-ITEMS] Items sorted and assigned to @Published property")
            print("🟡 [LOAD-ITEMS] Final items count: \(items.count)")
            isLoading = false
            print("🟡 [LOAD-ITEMS] ========================================")
        } catch {
            print("❌ [LOAD-ITEMS] ERROR loading items: \(error.localizedDescription)")
            print("🟡 [LOAD-ITEMS] ========================================")
            errorMessage = "No se pudieron cargar los items: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Item Operations

    /// Add new item from ItemDomain (incremental update pattern)
    /// ✅ Clean Architecture: Works with Domain models only
    func addItemFromDomain(_ itemDomain: ItemDomain) async {
        print("➕ [ADD] Adding new item from domain: '\(itemDomain.itemDescription)'")
        print("📊 [ADD] Current count BEFORE add: \(items.count)")

        // ✅ Add Domain model directly to array
        items.append(itemDomain)
        items.sort { $0.createdAt > $1.createdAt }
        print("📊 [ADD] New count AFTER add: \(items.count)")

        print("🎉 [ADD] Incremental update complete - NO Core Data conversion!")
    }

    /// Update existing item from ItemDomain (incremental update pattern)
    /// ✅ Clean Architecture: Works with Domain models only
    func updateItemFromDomain(_ itemDomain: ItemDomain) async {
        print("✏️ [EDIT] Updating item from domain: '\(itemDomain.itemDescription)'")

        // Find and update the item in the local array
        if let index = items.firstIndex(where: { $0.id == itemDomain.id }) {
            print("📊 [EDIT] Found item at index \(index), updating...")
            items[index] = itemDomain
            items.sort { $0.createdAt > $1.createdAt }
            print("✅ [EDIT] Item updated in local array")
        }

        print("🎉 [EDIT] Incremental update complete - NO Core Data conversion!")
    }

    /// Delete item (optimistic delete pattern)
    /// ✅ Clean Architecture: Works with Domain models only
    func deleteItem(_ itemDomain: ItemDomain, at index: Int) async {
        let itemDesc = itemDomain.itemDescription

        print("🗑️ [DELETE] Removing item: '\(itemDesc)'")
        print("📊 [DELETE] Current count BEFORE delete: \(items.count)")

        // Optimistic delete - remove from UI first
        items.remove(at: index)
        print("📊 [DELETE] New count AFTER delete: \(items.count)")

        // Delete from DB in background using Use Case
        do {
            try await deleteItemUseCase.execute(id: itemDomain.id)
            print("✅ [DELETE] Item deleted from DB")
            print("🎉 [DELETE] Optimistic delete complete!")
        } catch {
            // Rollback on error - add item back
            print("❌ [DELETE] Error deleting item, rolling back...")
            items.insert(itemDomain, at: index)
            errorMessage = "Error al eliminar item: \(error.localizedDescription)"
        }
    }

    /// Toggle isPaid on a single item (optimistic update + rollback on error)
    func toggleItemPaid(_ item: ItemDomain) async {
        let newIsPaid = !item.isPaid
        let updated = ItemDomain(
            id: item.id,
            itemDescription: item.itemDescription,
            amount: item.amount,
            quantity: item.quantity,
            itemListId: item.itemListId,
            createdAt: item.createdAt,
            lastModifiedAt: Date(),
            isPaid: newIsPaid
        )
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = updated
        }
        do {
            try await toggleItemPaidUseCase.execute(itemId: item.id, isPaid: newIsPaid)
        } catch {
            if let index = items.firstIndex(where: { $0.id == updated.id }) {
                items[index] = item
            }
            errorMessage = "Error al actualizar item"
        }
    }

    // MARK: - Formatting Helpers

    private func makeCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = currencyCode
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        return formatter
    }

    /// Get formatted total for all items in this ItemList
    /// ✅ Clean Architecture: Works with Domain models only
    func getFormattedTotal() -> String {
        let total = items.filter { $0.isPaid }.reduce(Decimal.zero) { result, item in
            let itemTotal = item.amount * Decimal(item.quantity)
            return result + itemTotal
        }
        return makeCurrencyFormatter().string(from: total as NSDecimalNumber) ?? "\(total) \(currencyCode)"
    }

    /// Get formatted amount for a specific item
    /// ✅ Clean Architecture: Works with Domain models only
    func getFormattedAmount(_ itemDomain: ItemDomain) -> String {
        let itemTotal = itemDomain.amount * Decimal(itemDomain.quantity)
        return makeCurrencyFormatter().string(from: itemTotal as NSDecimalNumber) ?? "\(itemTotal) \(currencyCode)"
    }
}
