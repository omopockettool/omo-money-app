//
//  ItemListDetailViewModel.swift
//  OMOMoney
//
//  Created by System on 29/11/25.
//

import Foundation
import CoreData
import SwiftUI

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

    // MARK: - Context & Cache
    private let context: NSManagedObjectContext
    private let itemList: ItemList
    private let cacheManager = CacheManager.shared

    // MARK: - Cache Keys
    private var serviceCacheKey: String {
        "ItemService.itemListItems.\(itemList.id?.uuidString ?? "nil")"
    }

    private var timestampKey: String {
        "\(serviceCacheKey).timestamp"
    }

    // MARK: - Initialization
    init(
        itemList: ItemList,
        context: NSManagedObjectContext,
        fetchItemsUseCase: FetchItemsUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase,
        deleteItemUseCase: DeleteItemUseCase
    ) {
        self.itemList = itemList
        self.context = context
        self.fetchItemsUseCase = fetchItemsUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase
        self.deleteItemUseCase = deleteItemUseCase
    }

    // MARK: - Data Loading

    /// Load items for the current ItemList
    func loadItems() async {
        // Only show loading spinner if we don't have data yet (initial load)
        // During refresh (pull-to-refresh), keep the existing list visible
        let isInitialLoad = items.isEmpty

        if isInitialLoad {
            print("📊 [LOAD] Initial load - showing spinner")
            isLoading = true
        } else {
            print("🔄 [REFRESH] Pull-to-refresh - keeping list visible")
        }
        errorMessage = nil

        do {
            guard let itemListId = itemList.id else {
                errorMessage = "ItemList ID no válido"
                isLoading = false
                return
            }

            print("🔍 [LOAD] Fetching items for ItemList: \(itemList.itemListDescription ?? "Unknown")")

            // ✅ Use case returns Domain models - use them directly!
            let itemDomains = try await fetchItemsUseCase.execute(forItemListId: itemListId)

            print("📦 [LOAD] Fetched \(itemDomains.count) items from Use Case")

            // ✅ Use Domain models directly, no Core Data conversion needed
            items = itemDomains.sorted { $0.createdAt > $1.createdAt }
            print("✅ [LOAD] Successfully loaded \(items.count) items")
            isLoading = false
        } catch {
            print("❌ [LOAD] Error loading items: \(error.localizedDescription)")
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

        // 🔄 Refresh ItemList context so dashboard sees updated total
        refreshItemListContext()

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

        // 🔄 Refresh ItemList context so dashboard sees updated total
        refreshItemListContext()

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

            // 🔄 Refresh ItemList context so dashboard sees updated total
            refreshItemListContext()

            print("🎉 [DELETE] Optimistic delete complete!")
        } catch {
            // Rollback on error - add item back
            print("❌ [DELETE] Error deleting item, rolling back...")
            items.insert(itemDomain, at: index)

            // Refresh ItemList to restore original state
            refreshItemListContext()

            errorMessage = "Error al eliminar item: \(error.localizedDescription)"
        }
    }

    /// Refresh the ItemList Core Data object from context without DB query
    /// This is useful when the ItemList itself is edited (description, date, category, etc.)
    /// and you want to instantly reflect changes in the navigation title or other UI elements
    func refreshItemListContext() {
        context.refresh(itemList, mergeChanges: true)
        print("🔄 [ITEMLIST-REFRESH] ItemList context refreshed with latest properties")
    }

    // MARK: - Formatting Helpers

    /// Get formatted total for all items in this ItemList
    /// ✅ Clean Architecture: Works with Domain models only
    func getFormattedTotal() -> String {
        let total = items.reduce(Decimal.zero) { result, item in
            let itemTotal = item.amount * Decimal(item.quantity)
            return result + itemTotal
        }

        let currencyCode = itemList.group?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        return formatter.string(from: total as NSDecimalNumber) ?? "\(total) \(currencyCode)"
    }

    /// Get formatted amount for a specific item
    /// ✅ Clean Architecture: Works with Domain models only
    func getFormattedAmount(_ itemDomain: ItemDomain) -> String {
        let itemTotal = itemDomain.amount * Decimal(itemDomain.quantity)

        let currencyCode = itemList.group?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        return formatter.string(from: itemTotal as NSDecimalNumber) ?? "\(itemTotal) \(currencyCode)"
    }
}
