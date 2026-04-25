import Foundation

protocol FetchItemListsUseCase {
    func execute(forGroupId groupId: UUID) async throws -> [SDItemList]
}

final class DefaultFetchItemListsUseCase: FetchItemListsUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute(forGroupId groupId: UUID) async throws -> [SDItemList] {
        return try await itemListRepository.fetchItemLists(forGroupId: groupId)
    }
}
