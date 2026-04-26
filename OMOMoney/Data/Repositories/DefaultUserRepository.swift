import Foundation
import SwiftData

@MainActor
final class DefaultUserRepository: UserRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchUsers() async throws -> [SDUser] {
        let descriptor = FetchDescriptor<SDUser>()
        return try context.fetch(descriptor)
    }

    func fetchUser(id: UUID) async throws -> SDUser? {
        let targetId = id
        let descriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetId })
        return try context.fetch(descriptor).first
    }

    func createUser(name: String, email: String) async throws -> SDUser {
        let user = SDUser(name: name, email: email)
        context.insert(user)
        try context.save()
        return user
    }

    func updateUser(_ user: SDUser) async throws {
        user.lastModifiedAt = Date()
        try context.save()
    }

    func deleteUser(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetId })
        guard let user = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(user)
        try context.save()
    }

    func searchUsers(query: String) async throws -> [SDUser] {
        let descriptor = FetchDescriptor<SDUser>()
        return try context.fetch(descriptor).filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - RepositoryError
enum RepositoryError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notFound:     return "The requested item was not found"
        case .invalidData:  return "The provided data is invalid"
        case .saveFailed:   return "Failed to save the item"
        case .deleteFailed: return "Failed to delete the item"
        }
    }
}
