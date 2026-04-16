import Foundation

protocol CreateUserUseCase {
    func execute(name: String, email: String) async throws -> SDUser
}

final class DefaultCreateUserUseCase: CreateUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute(name: String, email: String) async throws -> SDUser {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { throw ValidationError.emptyName }
        guard !trimmedEmail.isEmpty else { throw ValidationError.emptyEmail }
        guard trimmedEmail.contains("@") else { throw ValidationError.invalidEmail }

        return try await userRepository.createUser(name: trimmedName, email: trimmedEmail)
    }
}
