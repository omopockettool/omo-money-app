import Foundation

@MainActor
protocol ItemRepository {
    func fetchItems(forItemListId itemListId: UUID) async throws -> [SDItem]
    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem
    func updateItem(_ item: SDItem) async throws
    func deleteItem(id: UUID) async throws
    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws
    func toggleItemPaid(id: UUID, isPaid: Bool) async throws
}
