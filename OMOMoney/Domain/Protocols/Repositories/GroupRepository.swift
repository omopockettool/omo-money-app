import Foundation

@MainActor
protocol GroupRepository {
    func fetchGroup(id: UUID) async throws -> SDGroup?
    func createGroup(name: String, currency: String) async throws -> SDGroup
    func updateGroup(_ group: SDGroup) async throws
    func deleteGroup(id: UUID) async throws
    func fetchGroups(forUserId userId: UUID) async throws -> [SDGroup]
}
