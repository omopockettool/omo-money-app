import Foundation

protocol SearchUsersUseCase {
    func execute(query: String) async throws -> [SDUser]
}

final class DefaultSearchUsersUseCase: SearchUsersUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute(query: String) async throws -> [SDUser] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return try await userRepository.fetchUsers() }
        return try await userRepository.searchUsers(query: trimmedQuery)
    }
}
