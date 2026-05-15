import Foundation
import SwiftData
@testable import OMOMoney

/// In-memory SwiftData container for unit tests.
/// Each test should create its own instance for isolation.
@MainActor
final class SwiftDataTestContainer {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: SDUser.self, SDGroup.self, SDUserGroup.self,
                SDCategory.self, SDPaymentMethod.self,
                SDItemList.self, SDItem.self,
            configurations: config
        )
        context = container.mainContext
    }

    // MARK: - Repository factories

    func makeGroupRepository() -> GroupRepository {
        DefaultGroupRepository(context: context)
    }

    func makeCategoryRepository() -> CategoryRepository {
        DefaultCategoryRepository(context: context)
    }

    func makeItemListRepository() -> ItemListRepository {
        DefaultItemListRepository(context: context)
    }

    func makeItemRepository() -> ItemRepository {
        DefaultItemRepository(context: context)
    }

    // MARK: - Seed helpers

    func insertGroup(name: String = "Test Group", currency: String = "EUR") throws -> SDGroup {
        let group = SDGroup(name: name, currency: currency)
        context.insert(group)
        try context.save()
        return group
    }

    func insertCategory(name: String, group: SDGroup) throws -> SDCategory {
        let category = SDCategory(name: name)
        category.group = group
        context.insert(category)
        try context.save()
        return category
    }

    func insertItemList(description: String = "Lista", date: Date = Date(), group: SDGroup) throws -> SDItemList {
        let itemList = SDItemList(itemListDescription: description, date: date)
        itemList.group = group
        context.insert(itemList)
        try context.save()
        return itemList
    }

    @discardableResult
    func insertItem(
        description: String = "Item",
        amount: Double = 10.0,
        quantity: Int = 1,
        isPaid: Bool = false,
        itemList: SDItemList
    ) throws -> SDItem {
        let item = SDItem(
            itemDescription: description,
            amount: amount,
            quantity: quantity,
            isPaid: isPaid
        )
        item.itemList = itemList
        context.insert(item)
        try context.save()
        return item
    }
}
