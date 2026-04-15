//
//  AppDIContainer.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

/// Main Dependency Injection Container for the application
/// Centralizes the creation and management of dependencies
final class AppDIContainer {
    
    // MARK: - Singleton
    
    static let shared = AppDIContainer()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistenceController: PersistenceController = {
        return PersistenceController.shared
    }()
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    // MARK: - Services
    
    lazy var userService: UserServiceProtocol = {
        return UserService(context: viewContext)
    }()
    
    lazy var groupService: GroupServiceProtocol = {
        return GroupService(context: viewContext)
    }()
    
    lazy var categoryService: CategoryServiceProtocol = {
        return CategoryService(context: viewContext)
    }()
    
    lazy var paymentMethodService: PaymentMethodServiceProtocol = {
        return PaymentMethodService(context: viewContext)
    }()
    
    lazy var itemListService: ItemListServiceProtocol = {
        return ItemListService(context: viewContext)
    }()
    
    lazy var itemService: ItemServiceProtocol = {
        return ItemService(context: viewContext)
    }()
    
    lazy var userGroupService: UserGroupServiceProtocol = {
        return UserGroupService(context: viewContext)
    }()
    
    // MARK: - Repositories

    lazy var itemListRepository: ItemListRepository = {
        return DefaultItemListRepository(itemListService: itemListService, context: viewContext)
    }()

    lazy var itemRepository: ItemRepository = {
        return DefaultItemRepository(itemService: itemService, context: viewContext)
    }()

    lazy var categoryRepository: CategoryRepository = {
        return DefaultCategoryRepository(categoryService: categoryService)
    }()

    lazy var paymentMethodRepository: PaymentMethodRepository = {
        return DefaultPaymentMethodRepository(paymentMethodService: paymentMethodService)
    }()

    // MARK: - ItemList Use Cases
    func makeCreateItemListUseCase() -> CreateItemListUseCase {
        DefaultCreateItemListUseCase(itemListRepository: itemListRepository)
    }
    func makeFetchItemListsUseCase() -> FetchItemListsUseCase {
        DefaultFetchItemListsUseCase(itemListRepository: itemListRepository)
    }
    func makeUpdateItemListUseCase() -> UpdateItemListUseCase {
        DefaultUpdateItemListUseCase(itemListRepository: itemListRepository)
    }
    func makeDeleteItemListUseCase() -> DeleteItemListUseCase {
        DefaultDeleteItemListUseCase(itemListRepository: itemListRepository)
    }
    // MARK: - Item Use Cases
    func makeCreateItemUseCase() -> CreateItemUseCase {
        DefaultCreateItemUseCase(itemRepository: itemRepository)
    }
    func makeUpdateItemUseCase() -> UpdateItemUseCase {
        DefaultUpdateItemUseCase(itemRepository: itemRepository)
    }
    func makeDeleteItemUseCase() -> DeleteItemUseCase {
        DefaultDeleteItemUseCase(itemRepository: itemRepository)
    }
    func makeFetchItemsUseCase() -> FetchItemsUseCase {
        DefaultFetchItemsUseCase(itemRepository: itemRepository)
    }
    func makeToggleAllItemsPaidInListUseCase() -> ToggleAllItemsPaidInListUseCase {
        DefaultToggleAllItemsPaidInListUseCase(itemRepository: itemRepository)
    }
    func makeToggleItemPaidUseCase() -> ToggleItemPaidUseCase {
        DefaultToggleItemPaidUseCase(itemRepository: itemRepository)
    }

    // MARK: - Category Use Cases
    func makeFetchCategoriesUseCase() -> FetchCategoriesUseCase {
        DefaultFetchCategoriesUseCase(categoryRepository: categoryRepository)
    }
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase {
        DefaultCreateCategoryUseCase(categoryRepository: categoryRepository)
    }
    func makeUpdateCategoryUseCase() -> UpdateCategoryUseCase {
        DefaultUpdateCategoryUseCase(categoryRepository: categoryRepository)
    }
    func makeDeleteCategoryUseCase() -> DeleteCategoryUseCase {
        DefaultDeleteCategoryUseCase(categoryRepository: categoryRepository)
    }

    // MARK: - PaymentMethod Use Cases
    func makeFetchPaymentMethodsUseCase() -> FetchPaymentMethodsUseCase {
        DefaultFetchPaymentMethodsUseCase(paymentMethodRepository: paymentMethodRepository)
    }
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase {
        DefaultCreatePaymentMethodUseCase(paymentMethodRepository: paymentMethodRepository)
    }
    func makeUpdatePaymentMethodUseCase() -> UpdatePaymentMethodUseCase {
        DefaultUpdatePaymentMethodUseCase(paymentMethodRepository: paymentMethodRepository)
    }
    func makeDeletePaymentMethodUseCase() -> DeletePaymentMethodUseCase {
        DefaultDeletePaymentMethodUseCase(paymentMethodRepository: paymentMethodRepository)
    }

    // MARK: - User Use Cases
    func makeGetCurrentUserUseCase() -> GetCurrentUserUseCase {
        DefaultGetCurrentUserUseCase(userRepository: userRepository)
    }
    func makeCreateUserUseCase() -> CreateUserUseCase {
        DefaultCreateUserUseCase(userRepository: userRepository)
    }
    func makeUpdateUserUseCase() -> UpdateUserUseCase {
        DefaultUpdateUserUseCase(userRepository: userRepository)
    }
    func makeDeleteUserUseCase() -> DeleteUserUseCase {
        DefaultDeleteUserUseCase(userRepository: userRepository)
    }

    // MARK: - Group Use Cases
    func makeCreateGroupUseCase() -> CreateGroupUseCase {
        DefaultCreateGroupUseCase(groupRepository: groupRepository)
    }
    func makeFetchGroupsForUserUseCase() -> FetchGroupsForUserUseCase {
        DefaultFetchGroupsForUserUseCase(groupRepository: groupRepository)
    }

    // MARK: - UserGroup Use Cases
    func makeCreateUserGroupUseCase() -> CreateUserGroupUseCase {
        DefaultCreateUserGroupUseCase(userGroupRepository: userGroupRepository)
    }

    lazy var userRepository: UserRepository = {
        return DefaultUserRepository(userService: userService)
    }()
    
    lazy var groupRepository: GroupRepository = {
        return DefaultGroupRepository(
            groupService: groupService,
            userGroupService: userGroupService,
            context: viewContext
        )
    }()
    
    lazy var userGroupRepository: UserGroupRepository = {
        return DefaultUserGroupRepository(
            userGroupService: userGroupService,
            userService: userService,
            groupService: groupService,
            context: viewContext
        )
    }()
    
    // MARK: - Scene DIContainers
    
    func makeUserSceneDIContainer() -> UserSceneDIContainer {
        let dependencies = UserSceneDIContainer.Dependencies(
            userRepository: userRepository,
            groupRepository: groupRepository,
            userGroupRepository: userGroupRepository
        )
        return UserSceneDIContainer(dependencies: dependencies)
    }
    
    func makeGroupSceneDIContainer() -> GroupSceneDIContainer {
        let dependencies = GroupSceneDIContainer.Dependencies(
            groupRepository: groupRepository,
            userRepository: userRepository
        )
        return GroupSceneDIContainer(dependencies: dependencies)
    }
}
