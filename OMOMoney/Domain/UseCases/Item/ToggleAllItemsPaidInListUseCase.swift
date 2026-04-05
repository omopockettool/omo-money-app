import Foundation

protocol ToggleAllItemsPaidInListUseCase {
    func execute(itemListId: UUID, isPaid: Bool) async throws
}

final class DefaultToggleAllItemsPaidInListUseCase: ToggleAllItemsPaidInListUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(itemListId: UUID, isPaid: Bool) async throws {
        try await itemRepository.setAllItemsPaid(forItemListId: itemListId, isPaid: isPaid)
    }
}
