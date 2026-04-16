import Foundation

protocol UserRepository {
    func fetchUsers() async throws -> [SDUser]
    func fetchUser(id: UUID) async throws -> SDUser?
    func createUser(name: String, email: String) async throws -> SDUser
    func updateUser(_ user: SDUser) async throws
    func deleteUser(id: UUID) async throws
    func searchUsers(query: String) async throws -> [SDUser]
}
