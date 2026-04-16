import Foundation

protocol CreateItemUseCase {
    func execute(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem
}

final class DefaultCreateItemUseCase: CreateItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool = false
    ) async throws -> SDItem {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw ValidationError.invalidDescription }
        guard amount >= 0 else { throw ValidationError.invalidAmount }
        guard quantity > 0 else { throw ValidationError.invalidQuantity }
        return try await itemRepository.createItem(
            description: trimmedDescription,
            amount: amount,
            quantity: quantity,
            itemListId: itemListId,
            isPaid: isPaid
        )
    }
}
