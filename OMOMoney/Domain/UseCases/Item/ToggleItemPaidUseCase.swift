import Foundation

protocol ToggleItemPaidUseCase {
    func execute(itemId: UUID, isPaid: Bool) async throws
}

final class DefaultToggleItemPaidUseCase: ToggleItemPaidUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(itemId: UUID, isPaid: Bool) async throws {
        try await itemRepository.toggleItemPaid(id: itemId, isPaid: isPaid)
    }
}
