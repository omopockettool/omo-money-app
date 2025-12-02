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
    @Published var items: [Item] = []
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

            // Use case returns Domain models
            let itemDomains = try await fetchItemsUseCase.execute(forItemListId: itemListId)

            print("📦 [LOAD] Fetched \(itemDomains.count) items from Use Case")

            // Fetch Core Data entities from context (they were already persisted by the repository/service)
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "itemList == %@", itemList)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            items = try context.fetch(fetchRequest)
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
    /// Converts ItemDomain to Core Data entity and updates cache
    func addItemFromDomain(_ itemDomain: ItemDomain) async {
        print("➕ [ADD] Adding new item from domain: '\(itemDomain.itemDescription)'")
        print("📊 [ADD] Current count BEFORE add: \(items.count)")

        // Fetch the Core Data entity that was created by the Use Case/Service
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", itemDomain.id as CVarArg)

        do {
            guard let newItem = try context.fetch(fetchRequest).first else {
                print("❌ [ADD] Could not find Core Data entity for item: \(itemDomain.id)")
                return
            }

            // Add to local array
            items.append(newItem)
            items.sort { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
            print("📊 [ADD] New count AFTER add: \(items.count)")

            // 🎯 UPDATE SERVICE CACHE: Single source of truth
            await cacheManager.cacheData(items, for: serviceCacheKey)
            await cacheManager.cacheData(Date(), for: timestampKey)
            print("✅ [ADD] Service cache updated with \(items.count) items")

            // Clear calculation cache
            await cacheManager.clearCalculationCache(for: "ItemService.itemListTotalAmount")

            // 🔄 Refresh ItemList context so dashboard sees updated total
            refreshItemListContext()

            print("🎉 [ADD] Incremental update complete - NO DB query!")
        } catch {
            print("❌ [ADD] Error fetching item: \(error.localizedDescription)")
        }
    }

    /// Update existing item from ItemDomain (incremental update pattern)
    /// Converts ItemDomain to Core Data entity and updates cache
    func updateItemFromDomain(_ itemDomain: ItemDomain) async {
        print("✏️ [EDIT] Updating item from domain: '\(itemDomain.itemDescription)'")

        // Fetch the updated Core Data entity
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", itemDomain.id as CVarArg)

        do {
            guard let updatedItem = try context.fetch(fetchRequest).first else {
                print("❌ [EDIT] Could not find Core Data entity for item: \(itemDomain.id)")
                return
            }

            // Find and update the item in the local array
            if let index = items.firstIndex(where: { $0.id == itemDomain.id }) {
                print("📊 [EDIT] Found item at index \(index), updating...")
                items[index] = updatedItem
                items.sort { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
                print("✅ [EDIT] Item updated in local array")
            }

            // 🎯 UPDATE SERVICE CACHE: Single source of truth
            await cacheManager.cacheData(items, for: serviceCacheKey)
            await cacheManager.cacheData(Date(), for: timestampKey)
            print("✅ [EDIT] Service cache updated with \(items.count) items")

            // Clear calculation cache
            await cacheManager.clearCalculationCache(for: "ItemService.itemListTotalAmount")

            // 🔄 Refresh ItemList context so dashboard sees updated total
            refreshItemListContext()

            print("🎉 [EDIT] Incremental update complete - NO DB query!")
        } catch {
            print("❌ [EDIT] Error fetching item: \(error.localizedDescription)")
        }
    }

    /// Delete item (optimistic delete pattern)
    func deleteItem(_ item: Item, at index: Int) async {
        guard let itemId = item.id else {
            errorMessage = "Item ID no válido"
            return
        }

        let itemDesc = item.itemDescription ?? "Unknown"

        print("🗑️ [DELETE] Removing item: '\(itemDesc)'")
        print("📊 [DELETE] Current count BEFORE delete: \(items.count)")

        // Optimistic delete - remove from UI first
        items.remove(at: index)
        print("📊 [DELETE] New count AFTER delete: \(items.count)")

        // 🎯 UPDATE SERVICE CACHE: Single source of truth
        await cacheManager.cacheData(items, for: serviceCacheKey)
        await cacheManager.cacheData(Date(), for: timestampKey)
        print("✅ [DELETE] Service cache updated with \(items.count) items")

        // Delete from DB in background using Use Case
        do {
            try await deleteItemUseCase.execute(id: itemId)
            print("✅ [DELETE] Item deleted from DB")

            // Clear calculation cache
            await cacheManager.clearCalculationCache(for: "ItemService.itemListTotalAmount")

            // 🔄 Refresh ItemList context so dashboard sees updated total
            refreshItemListContext()

            print("🎉 [DELETE] Optimistic delete complete!")
        } catch {
            // Rollback on error - add item back
            print("❌ [DELETE] Error deleting item, rolling back...")
            items.insert(item, at: index)

            // Rollback cache
            await cacheManager.cacheData(items, for: serviceCacheKey)
            await cacheManager.cacheData(Date(), for: timestampKey)

            // Refresh ItemList to restore original state
            refreshItemListContext()

            errorMessage = "Error al eliminar item: \(error.localizedDescription)"
        }
    }

    // MARK: - Context Refresh

    /// Refresh Item Core Data objects from context without DB query
    /// This is called when returning from AddItemView sheet to instantly reflect changes
    /// Pattern: Same as DashboardViewModel.refreshItemListContexts()
    func refreshItemContexts() {
        print("🔄 [CONTEXT-REFRESH] Refreshing \(items.count) Item objects from Core Data context...")

        for item in items {
            context.refresh(item, mergeChanges: true)
        }

        // Also refresh the parent ItemList to update totals
        refreshItemListContext()

        print("✅ [CONTEXT-REFRESH] All Item objects refreshed - NO DB query!")
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
    func getFormattedTotal() -> String {
        let total = items.reduce(NSDecimalNumber.zero) { result, item in
            let itemTotal = item.amount?.multiplying(by: NSDecimalNumber(value: item.quantity))
            return result.adding(itemTotal ?? .zero)
        }

        let currencyCode = itemList.group?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        return formatter.string(from: total) ?? "\(total) \(currencyCode)"
    }

    /// Get formatted amount for a specific item
    func getFormattedAmount(_ item: Item) -> String {
        let itemTotal = item.amount?.multiplying(by: NSDecimalNumber(value: item.quantity)) ?? .zero

        let currencyCode = itemList.group?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        return formatter.string(from: itemTotal) ?? "\(itemTotal) \(currencyCode)"
    }
}
