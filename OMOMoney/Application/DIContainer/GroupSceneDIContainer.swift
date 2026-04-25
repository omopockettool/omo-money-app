//
//  GroupSceneDIContainer.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Dependency Injection Container for Group-related features
/// Provides dependencies for Group scene ViewModels and Use Cases
final class GroupSceneDIContainer {
    
    // MARK: - Dependencies
    
    struct Dependencies {
        let groupRepository: GroupRepository
        let userRepository: UserRepository
    }
    
    private let dependencies: Dependencies
    
    // MARK: - Initialization
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Use Cases
    
    func makeCreateGroupUseCase() -> CreateGroupUseCase {
        return DefaultCreateGroupUseCase(groupRepository: dependencies.groupRepository)
    }

    func makeDeleteGroupUseCase() -> DeleteGroupUseCase {
        return DefaultDeleteGroupUseCase(groupRepository: dependencies.groupRepository)
    }
    
    // MARK: - ViewModels (for future use)
    
    // Example of how to create ViewModels with Use Cases:
    /*
    func makeGroupListViewModel() -> GroupListViewModel {
        return GroupListViewModel(
            fetchGroupsUseCase: makeFetchGroupsUseCase(),
            deleteGroupUseCase: makeDeleteGroupUseCase()
        )
    }
    
    func makeCreateGroupViewModel() -> CreateGroupViewModel {
        return CreateGroupViewModel(
            createGroupUseCase: makeCreateGroupUseCase()
        )
    }
    */
}
