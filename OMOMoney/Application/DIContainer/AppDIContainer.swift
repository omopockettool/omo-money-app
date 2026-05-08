import Foundation
import SwiftData

/// Main Dependency Injection Container for the application
/// Phase 3: Services replaced — repositories use ModelContext directly
@MainActor
final class AppDIContainer {

    // MARK: - Singleton

    static let shared = AppDIContainer()

    // MARK: - SwiftData Context

    private let context: ModelContext

    // MARK: - Repositories

    let userRepository: UserRepository
    let groupRepository: GroupRepository
    let categoryRepository: CategoryRepository
    let paymentMethodRepository: PaymentMethodRepository
    let itemListRepository: ItemListRepository
    let itemRepository: ItemRepository
    let userGroupRepository: UserGroupRepository
    let backupRepository: BackupRepository

    // MARK: - Init

    private init() {
        context = ModelContainer.shared.mainContext
        userRepository = DefaultUserRepository(context: context)
        groupRepository = DefaultGroupRepository(context: context)
        categoryRepository = DefaultCategoryRepository(context: context)
        paymentMethodRepository = DefaultPaymentMethodRepository(context: context)
        itemListRepository = DefaultItemListRepository(context: context)
        itemRepository = DefaultItemRepository(context: context)
        userGroupRepository = DefaultUserGroupRepository(context: context)
        backupRepository = DefaultBackupRepository(context: context)
    }

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
    func makeUpdateGroupUseCase() -> UpdateGroupUseCase {
        DefaultUpdateGroupUseCase(groupRepository: groupRepository)
    }
    func makeDeleteGroupUseCase() -> DeleteGroupUseCase {
        DefaultDeleteGroupUseCase(groupRepository: groupRepository)
    }

    // MARK: - UserGroup Use Cases

    func makeCreateUserGroupUseCase() -> CreateUserGroupUseCase {
        DefaultCreateUserGroupUseCase(userGroupRepository: userGroupRepository)
    }

    // MARK: - Backup Use Cases

    func makeCreateBackupUseCase() -> CreateBackupUseCase {
        DefaultCreateBackupUseCase(backupRepository: backupRepository)
    }

    func makeImportBackupUseCase() -> ImportBackupUseCase {
        DefaultImportBackupUseCase(backupRepository: backupRepository)
    }

    func makeGetBackupStatisticsUseCase() -> GetBackupStatisticsUseCase {
        DefaultGetBackupStatisticsUseCase(backupRepository: backupRepository)
    }

    func makeSettingsBackupViewModel() -> SettingsBackupViewModel {
        SettingsBackupViewModel(
            createBackupUseCase: makeCreateBackupUseCase(),
            importBackupUseCase: makeImportBackupUseCase(),
            getBackupStatisticsUseCase: makeGetBackupStatisticsUseCase()
        )
    }
}
