import Foundation

protocol ItemListRepository {
    func fetchItemLists(forGroupId groupId: UUID) async throws -> [SDItemList]
    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList
    func updateItemList(_ itemList: SDItemList) async throws
    func deleteItemList(id: UUID) async throws
}
