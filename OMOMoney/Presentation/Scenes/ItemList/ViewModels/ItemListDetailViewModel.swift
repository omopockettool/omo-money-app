//
//  ItemListDetailViewModel.swift
//  OMOMoney
//

import Foundation
import SwiftUI

enum ItemListDetailHeroStatus {
    case neutral
    case pending(String)
    case completed
}

@MainActor

@Observable
class ItemListDetailViewModel {

    // MARK: - Published Properties
    var items: [SDItem] = []
    var isLoading = true
    var errorMessage: String?

    // MARK: - Use Cases
    private let fetchItemsUseCase: FetchItemsUseCase
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase
    private let deleteItemUseCase: DeleteItemUseCase
    private let toggleItemPaidUseCase: ToggleItemPaidUseCase

    // MARK: - Model & Cache
    private let itemList: SDItemList
    private let currencyCode: String
    private let cacheManager = CacheManager.shared

    // MARK: - Cache Keys
    private var serviceCacheKey: String {
        "ItemService.itemListItems.\(itemList.id.uuidString)"
    }

    private var timestampKey: String {
        "\(serviceCacheKey).timestamp"
    }

    // MARK: - Initialization
    init(
        itemList: SDItemList,
        currencyCode: String,
        fetchItemsUseCase: FetchItemsUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase,
        deleteItemUseCase: DeleteItemUseCase,
        toggleItemPaidUseCase: ToggleItemPaidUseCase
    ) {
        self.itemList = itemList
        self.currencyCode = currencyCode
        self.fetchItemsUseCase = fetchItemsUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase
        self.deleteItemUseCase = deleteItemUseCase
        self.toggleItemPaidUseCase = toggleItemPaidUseCase
    }

    // MARK: - Data Loading

    func loadItems() async {
        print("🟡 [LOAD-ITEMS] Loading items for ItemList: '\(itemList.itemListDescription)'")

        let isInitialLoad = items.isEmpty

        if isInitialLoad {
            isLoading = true
        }
        errorMessage = nil

        do {
            let fetchedItems = try await fetchItemsUseCase.execute(forItemListId: itemList.id)

            items = sortItems(fetchedItems)
            print("✅ [LOAD-ITEMS] Loaded \(items.count) items")
            isLoading = false
        } catch {
            print("❌ [LOAD-ITEMS] ERROR loading items: \(error.localizedDescription)")
            errorMessage = "No se pudieron cargar los artículos: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Item Operations

    func addItem(_ item: SDItem) async {
        print("➕ [ADD] Adding new item: '\(item.itemDescription)'")
        items.append(item)
        items = sortItems(items)
        print("📊 [ADD] New count: \(items.count)")
    }

    func updateItem(_ item: SDItem) async {
        print("✏️ [EDIT] Updating item: '\(item.itemDescription)'")
        // SDItem is a reference type — the object is already updated in place.
        // Re-sort in case payment status or lastModifiedAt ordering changed.
        items = sortItems(items)
        print("✅ [EDIT] Item updated")
    }

    func deleteItem(_ item: SDItem, at index: Int) async {
        withAnimation { items.remove(at: index) }
        do {
            try await deleteItemUseCase.execute(id: item.id)
        } catch {
            withAnimation { items.insert(item, at: index) }
        }
    }

    func toggleItemPaid(_ item: SDItem) async {
        let newIsPaid = !item.isPaid
        let previousLastModifiedAt = item.lastModifiedAt
        item.isPaid = newIsPaid
        item.lastModifiedAt = Date()
        withAnimation(.easeInOut(duration: 0.2)) {
            items = sortItems(items)
        }
        do {
            try await toggleItemPaidUseCase.execute(itemId: item.id, isPaid: newIsPaid)
        } catch {
            item.isPaid = !newIsPaid
            item.lastModifiedAt = previousLastModifiedAt
            withAnimation(.easeInOut(duration: 0.2)) {
                items = sortItems(items)
            }
        }
    }

    // MARK: - Formatting Helpers

    private func sortItems(_ items: [SDItem]) -> [SDItem] {
        items.sorted { lhs, rhs in
            if lhs.isPaid != rhs.isPaid {
                return lhs.isPaid == false
            }

            return sortDate(for: lhs) > sortDate(for: rhs)
        }
    }

    private func sortDate(for item: SDItem) -> Date {
        item.isPaid ? (item.lastModifiedAt ?? item.createdAt) : item.createdAt
    }

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

    func getFormattedTotal() -> String {
        let total = items.filter { $0.isPaid }.reduce(0.0) { result, item in
            result + item.totalAmount
        }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "\(total) \(currencyCode)"
    }

    func getFormattedUnpaidTotal() -> String? {
        let unpaid = items.filter { !$0.isPaid }.reduce(0.0) { $0 + $1.totalAmount }
        guard unpaid > 0 else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: unpaid)) ?? "\(unpaid) \(currencyCode)"
    }

    func getHeroStatus() -> ItemListDetailHeroStatus {
        guard !items.isEmpty else {
            return .neutral
        }

        let hasUnpaidItems = items.contains { !$0.isPaid }
        if hasUnpaidItems {
            return .pending(getFormattedUnpaidTotal() ?? "")
        }

        return .completed
    }

    func getFormattedAmount(_ item: SDItem) -> String {
        return makeCurrencyFormatter().string(from: NSNumber(value: item.totalAmount)) ?? "\(item.totalAmount) \(currencyCode)"
    }
}
