import Foundation

protocol FetchItemListsUseCase {
    func execute() async throws -> [SDItemList]
    func execute(itemListId: UUID) async throws -> SDItemList?
    func execute(forGroupId groupId: UUID) async throws -> [SDItemList]
    func execute(forCategoryId categoryId: UUID) async throws -> [SDItemList]
    func execute(from startDate: Date, to endDate: Date) async throws -> [SDItemList]
}

final class DefaultFetchItemListsUseCase: FetchItemListsUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute() async throws -> [SDItemList] {
        return try await itemListRepository.fetchItemLists()
    }

    func execute(itemListId: UUID) async throws -> SDItemList? {
        return try await itemListRepository.fetchItemList(id: itemListId)
    }

    func execute(forGroupId groupId: UUID) async throws -> [SDItemList] {
        return try await itemListRepository.fetchItemLists(forGroupId: groupId)
    }

    func execute(forCategoryId categoryId: UUID) async throws -> [SDItemList] {
        return try await itemListRepository.fetchItemLists(forCategoryId: categoryId)
    }

    func execute(from startDate: Date, to endDate: Date) async throws -> [SDItemList] {
        return try await itemListRepository.fetchItemLists(from: startDate, to: endDate)
    }
}
