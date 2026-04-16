import Foundation

protocol FetchItemsUseCase {
    func execute() async throws -> [SDItem]
    func execute(itemId: UUID) async throws -> SDItem?
    func execute(forItemListId itemListId: UUID) async throws -> [SDItem]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute() async throws -> [SDItem] {
        return try await itemRepository.fetchItems()
    }

    func execute(itemId: UUID) async throws -> SDItem? {
        return try await itemRepository.fetchItem(id: itemId)
    }

    func execute(forItemListId itemListId: UUID) async throws -> [SDItem] {
        return try await itemRepository.fetchItems(forItemListId: itemListId)
    }
}
