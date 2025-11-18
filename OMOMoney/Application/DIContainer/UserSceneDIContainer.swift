//
//  UserSceneDIContainer.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Dependency Injection Container for User-related features
/// Provides dependencies for User scene ViewModels and Use Cases
final class UserSceneDIContainer {
    
    // MARK: - Dependencies
    
    struct Dependencies {
        let userRepository: UserRepository
        let groupRepository: GroupRepository
        let userGroupRepository: UserGroupRepository
    }
    
    private let dependencies: Dependencies
    
    // MARK: - Initialization
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Use Cases
    
    func makeFetchUsersUseCase() -> FetchUsersUseCase {
        return DefaultFetchUsersUseCase(userRepository: dependencies.userRepository)
    }
    
    func makeCreateUserUseCase() -> CreateUserUseCase {
        return DefaultCreateUserUseCase(userRepository: dependencies.userRepository)
    }
    
    func makeUpdateUserUseCase() -> UpdateUserUseCase {
        return DefaultUpdateUserUseCase(userRepository: dependencies.userRepository)
    }
    
    func makeDeleteUserUseCase() -> DeleteUserUseCase {
        return DefaultDeleteUserUseCase(userRepository: dependencies.userRepository)
    }
    
    func makeSearchUsersUseCase() -> SearchUsersUseCase {
        return DefaultSearchUsersUseCase(userRepository: dependencies.userRepository)
    }
    
    func makeCreateUserGroupUseCase() -> CreateUserGroupUseCase {
        return DefaultCreateUserGroupUseCase(userGroupRepository: dependencies.userGroupRepository)
    }
    
    // MARK: - ViewModels (for future use)
    
    // Example of how to create ViewModels with Use Cases:
    /*
    func makeUserListViewModel() -> UserListViewModel {
        return UserListViewModel(
            fetchUsersUseCase: makeFetchUsersUseCase(),
            deleteUserUseCase: makeDeleteUserUseCase(),
            searchUsersUseCase: makeSearchUsersUseCase()
        )
    }
    
    func makeCreateUserViewModel() -> CreateUserViewModel {
        return CreateUserViewModel(
            createUserUseCase: makeCreateUserUseCase()
        )
    }
    */
}
