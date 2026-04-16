import Foundation

protocol FetchUsersUseCase {
    func execute() async throws -> [SDUser]
}

final class DefaultFetchUsersUseCase: FetchUsersUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute() async throws -> [SDUser] {
        return try await userRepository.fetchUsers().filter { $0.isValid }
    }
}
