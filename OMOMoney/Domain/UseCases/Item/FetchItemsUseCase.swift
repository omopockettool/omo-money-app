import Foundation

protocol FetchItemsUseCase {
    func execute(forItemListId itemListId: UUID) async throws -> [SDItem]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(forItemListId itemListId: UUID) async throws -> [SDItem] {
        return try await itemRepository.fetchItems(forItemListId: itemListId)
    }
}
