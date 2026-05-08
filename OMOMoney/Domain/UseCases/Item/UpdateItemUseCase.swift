import Foundation

protocol UpdateItemUseCase {
    func execute(_ item: SDItem) async throws
}

final class DefaultUpdateItemUseCase: UpdateItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(_ item: SDItem) async throws {
        let trimmedDescription = item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw ValidationError.invalidDescription }
        guard item.amount >= 0 else { throw ValidationError.invalidAmount }
        guard item.quantity > 0 else { throw ValidationError.invalidQuantity }
        try await itemRepository.updateItem(item)
    }
}
