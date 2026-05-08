import Foundation

protocol UpdateItemListUseCase {
    func execute(_ itemList: SDItemList) async throws
}

final class DefaultUpdateItemListUseCase: UpdateItemListUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute(_ itemList: SDItemList) async throws {
        try await itemListRepository.updateItemList(itemList)
    }
}
