import Foundation

protocol CreateItemListUseCase {
    func execute(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList
}

final class DefaultCreateItemListUseCase: CreateItemListUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList {
        return try await itemListRepository.createItemList(
            description: description,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId
        )
    }
}
