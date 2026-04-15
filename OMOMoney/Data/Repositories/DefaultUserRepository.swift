import Foundation
import SwiftData

final class DefaultUserRepository: UserRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchUsers() async throws -> [UserDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDUser>()
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchUser(id: UUID) async throws -> UserDomain? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first?.toDomain()
        }
    }

    func createUser(name: String, email: String) async throws -> UserDomain {
        try await MainActor.run {
            let user = SDUser(name: name, email: email)
            context.insert(user)
            try context.save()
            return user.toDomain()
        }
    }

    func updateUser(_ user: UserDomain) async throws {
        try await MainActor.run {
            let targetId = user.id
            let descriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetId })
            guard let existing = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            existing.name = user.name
            existing.email = user.email
            existing.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deleteUser(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetId })
            guard let user = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(user)
            try context.save()
        }
    }

    func searchUsers(query: String) async throws -> [UserDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDUser>()
            return try context.fetch(descriptor)
                .filter {
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    $0.email.localizedCaseInsensitiveContains(query)
                }
                .map { $0.toDomain() }
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

// MARK: - Domain mapping
private extension SDUser {
    func toDomain() -> UserDomain {
        UserDomain(id: id, name: name, email: email, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }
}
