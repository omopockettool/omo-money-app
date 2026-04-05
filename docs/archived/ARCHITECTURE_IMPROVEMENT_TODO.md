# 🏗️ Architecture Improvement Plan for OMOMoney

## Comparison with iOS-Clean-Architecture-MVVM Template

---

## 📊 Overall Assessment

### ✅ **Your Project Strengths**

1. **Modern SwiftUI Implementation** - Using iOS 18.5+ APIs (ahead of template)
2. **Good Service Layer** - Protocol-based services with dependency injection
3. **Proper Threading** - Background operations with Core Data
4. **Caching System** - Intelligent caching already implemented
5. **Comprehensive Testing** - Service layer tests exist
6. **Modern Swift Concurrency** - Using async/await throughout
7. **@MainActor Usage** - Proper UI thread safety

### ⚠️ **Areas for Improvement (Inspired by Template)**

1. **Missing Domain Layer** - No separation of business logic from infrastructure
2. **No Use Cases Layer** - Business logic mixed into ViewModels and Services
3. **Missing Repository Pattern** - Services directly tied to Core Data
4. **No Flow Coordinators** - Navigation logic scattered across views
5. **Missing DTO Layer** - Core Data entities exposed directly to presentation
6. **No Data Transfer Service** - No abstraction for data operations
7. **Tight Coupling** - ViewModels depend on concrete Core Data implementations
8. **No Observable Pattern** - Using @Published but could benefit from custom Observable
9. **Missing DI Container** - Services created inline instead of centralized container

---

## 🎯 Recommended Improvements

### **Priority 1: Critical Architecture Changes** 🔴

#### 1.1 **Implement Domain Layer**

**Why**: Separates business logic from infrastructure, making code more testable and maintainable.

**What to do**:

- [ ] Create `Domain/` directory with:
  - `Entities/` - Pure Swift domain models (not Core Data)
  - `UseCases/` - Business logic operations
  - `Interfaces/Repositories/` - Repository protocols
- [ ] Define domain entities:
  ```swift
  // Domain/Entities/User.swift
  struct UserDomain {
      let id: UUID
      let name: String
      let email: String
      let createdAt: Date
      // No Core Data dependencies
  }
  ```
- [ ] Create repository interfaces:
  ```swift
  // Domain/Interfaces/Repositories/UserRepository.swift
  protocol UserRepository {
      func fetchUsers() async throws -> [UserDomain]
      func createUser(name: String, email: String) async throws -> UserDomain
      func updateUser(_ user: UserDomain) async throws
      func deleteUser(id: UUID) async throws
  }
  ```

**Benefits**:

- Business logic independent of Core Data
- Easy to switch persistence layer
- Simplified testing with mocks
- Better separation of concerns

---

#### 1.2 **Implement Use Cases Layer**

**Why**: Encapsulates business logic in single-responsibility classes, making each operation testable and reusable.

**What to do**:

- [ ] Create `Domain/UseCases/` directory
- [ ] Extract business logic from ViewModels into Use Cases:

  ```swift
  // Domain/UseCases/CreateUserUseCase.swift
  protocol CreateUserUseCase {
      func execute(name: String, email: String) async throws -> UserDomain
  }

  final class DefaultCreateUserUseCase: CreateUserUseCase {
      private let userRepository: UserRepository

      init(userRepository: UserRepository) {
          self.userRepository = userRepository
      }

      func execute(name: String, email: String) async throws -> UserDomain {
          // Business validation logic here
          guard !name.isEmpty else {
              throw ValidationError.emptyName
          }

          // Call repository
          return try await userRepository.createUser(name: name, email: email)
      }
  }
  ```

- [ ] Create Use Cases for each major operation:
  - `FetchUsersUseCase`
  - `CreateGroupUseCase`
  - `AddEntryUseCase`
  - `CalculateTotalExpensesUseCase`
  - etc.

**Benefits**:

- ViewModels become thinner (only presentation logic)
- Business logic is reusable across features
- Each use case is independently testable
- Clear single responsibility

---

#### 1.3 **Implement Repository Pattern**

**Why**: Abstracts data source implementation, allowing flexibility to change persistence layer.

**What to do**:

- [ ] Create `Data/Repositories/` directory
- [ ] Implement repositories that conform to domain interfaces:
  ```swift
  // Data/Repositories/DefaultUserRepository.swift
  final class DefaultUserRepository: UserRepository {
      private let coreDataService: UserServiceProtocol // existing service

      init(coreDataService: UserServiceProtocol) {
          self.coreDataService = coreDataService
      }

      func fetchUsers() async throws -> [UserDomain] {
          let coreDataUsers = try await coreDataService.fetchUsers()
          return coreDataUsers.map { $0.toDomain() } // DTO mapping
      }

      func createUser(name: String, email: String) async throws -> UserDomain {
          let user = try await coreDataService.createUser(name: name, email: email)
          return user.toDomain()
      }
  }
  ```
- [ ] Create DTO mapping extensions:
  ```swift
  // Data/Repositories/DTOMapping/User+Mapping.swift
  extension User {
      func toDomain() -> UserDomain {
          return UserDomain(
              id: self.id!,
              name: self.name ?? "",
              email: self.email ?? "",
              createdAt: self.createdAt ?? Date()
          )
      }
  }
  ```

**Benefits**:

- Core Data entities hidden from ViewModels
- Can add API/network repositories later
- Easy to implement caching at repository level
- Testable with mock repositories

---

### **Priority 2: Navigation & Coordination** 🟡

#### 2.1 **Implement Flow Coordinators**

**Why**: Separates navigation logic from views, making flows reusable and testable.

**What to do**:

- [ ] Create `Presentation/Flows/` directory
- [ ] Implement coordinators for major flows:

  ```swift
  // Presentation/Flows/UserFlowCoordinator.swift
  protocol UserFlowCoordinatorDependencies {
      func makeUserListView(actions: UserListViewModelActions) -> UserListView
      func makeCreateUserView(onCreate: @escaping (UserDomain) -> Void) -> CreateUserView
      func makeEditUserView(user: UserDomain, onUpdate: @escaping () -> Void) -> EditUserView
  }

  final class UserFlowCoordinator {
      private let navigationController: UINavigationController
      private let dependencies: UserFlowCoordinatorDependencies

      init(
          navigationController: UINavigationController,
          dependencies: UserFlowCoordinatorDependencies
      ) {
          self.navigationController = navigationController
          self.dependencies = dependencies
      }

      func start() {
          let actions = UserListViewModelActions(
              showUserDetails: showUserDetails,
              showCreateUser: showCreateUser
          )
          let view = dependencies.makeUserListView(actions: actions)
          navigationController.pushViewController(UIHostingController(rootView: view), animated: false)
      }

      private func showUserDetails(user: UserDomain) {
          // Navigate to user details
      }

      private func showCreateUser() {
          // Navigate to create user
      }
  }
  ```

- [ ] Create coordinators for:
  - `UserFlowCoordinator`
  - `GroupFlowCoordinator`
  - `EntryFlowCoordinator`
  - `AppFlowCoordinator` (main coordinator)

**Benefits**:

- Views don't manage navigation
- Navigation flows are testable
- Easy to reuse flows in different contexts
- Cleaner view code

---

#### 2.2 **Implement ViewModelActions Pattern**

**Why**: Decouples ViewModels from navigation, making them more testable.

**What to do**:

- [ ] Define actions structs for ViewModels:
  ```swift
  // Presentation/User/UserList/UserListViewModelActions.swift
  struct UserListViewModelActions {
      let showUserDetails: (UserDomain) -> Void
      let showCreateUser: () -> Void
      let showSettings: () -> Void
  }
  ```
- [ ] Update ViewModels to use actions instead of direct navigation:
  ```swift
  // Presentation/User/UserList/UserListViewModel.swift
  @MainActor
  final class UserListViewModel: ObservableObject {
      private let fetchUsersUseCase: FetchUsersUseCase
      private let actions: UserListViewModelActions?

      init(
          fetchUsersUseCase: FetchUsersUseCase,
          actions: UserListViewModelActions? = nil
      ) {
          self.fetchUsersUseCase = fetchUsersUseCase
          self.actions = actions
      }

      func didSelectUser(_ user: UserDomain) {
          actions?.showUserDetails(user)
      }

      func didTapCreateUser() {
          actions?.showCreateUser()
      }
  }
  ```

**Benefits**:

- ViewModels can be tested without navigation
- Actions are injected by coordinators
- Clear separation of concerns

---

### **Priority 3: Dependency Injection Container** 🟢

#### 3.1 **Create App DI Container**

**Why**: Centralizes dependency creation and management.

**What to do**:

- [ ] Create `Application/DIContainer/` directory
- [ ] Implement main DI container:
  ```swift
  // Application/DIContainer/AppDIContainer.swift
  final class AppDIContainer {

      // MARK: - Core Data Stack
      lazy var persistenceController: PersistenceController = {
          return PersistenceController.shared
      }()

      // MARK: - Services
      lazy var userService: UserServiceProtocol = {
          return UserService(context: persistenceController.container.viewContext)
      }()

      lazy var groupService: GroupServiceProtocol = {
          return GroupService(context: persistenceController.container.viewContext)
      }()

      // MARK: - Repositories
      lazy var userRepository: UserRepository = {
          return DefaultUserRepository(coreDataService: userService)
      }()

      lazy var groupRepository: GroupRepository = {
          return DefaultGroupRepository(coreDataService: groupService)
      }()

      // MARK: - Scene DIContainers
      func makeUserSceneDIContainer() -> UserSceneDIContainer {
          let dependencies = UserSceneDIContainer.Dependencies(
              userRepository: userRepository,
              groupRepository: groupRepository
          )
          return UserSceneDIContainer(dependencies: dependencies)
      }
  }
  ```
- [ ] Create scene-specific DI containers:
  ```swift
  // Application/DIContainer/UserSceneDIContainer.swift
  final class UserSceneDIContainer {

      struct Dependencies {
          let userRepository: UserRepository
          let groupRepository: GroupRepository
      }

      private let dependencies: Dependencies

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

      // MARK: - Flow Coordinators
      func makeUserFlowCoordinator(
          navigationController: UINavigationController
      ) -> UserFlowCoordinator {
          return UserFlowCoordinator(
              navigationController: navigationController,
              dependencies: self
          )
      }

      // MARK: - Views
      func makeUserListView(actions: UserListViewModelActions) -> UserListView {
          let viewModel = makeUserListViewModel(actions: actions)
          return UserListView(viewModel: viewModel)
      }

      private func makeUserListViewModel(
          actions: UserListViewModelActions
      ) -> UserListViewModel {
          return UserListViewModel(
              fetchUsersUseCase: makeFetchUsersUseCase(),
              actions: actions
          )
      }
  }
  ```

**Benefits**:

- Centralized dependency management
- Easy to swap implementations
- Clear dependency graph
- Simplified testing with mock containers

---

### **Priority 4: Data Layer Improvements** 🟢

#### 4.1 **Implement DTO Pattern**

**Why**: Separates Core Data entities from domain models, reducing coupling.

**What to do**:

- [ ] Create `Data/PersistentStorages/DTOMapping/` directory
- [ ] Keep Core Data entities in `CoreDataStack/`
- [ ] Create mapping extensions:

  ```swift
  // Data/PersistentStorages/DTOMapping/User+Mapping.swift
  extension User {
      func toDomain() -> UserDomain {
          return UserDomain(
              id: self.id!,
              name: self.name ?? "",
              email: self.email ?? "",
              createdAt: self.createdAt!,
              isActive: self.isActive
          )
      }

      func update(from domain: UserDomain) {
          self.name = domain.name
          self.email = domain.email
          self.isActive = domain.isActive
      }
  }

  extension UserDomain {
      func toCoreData(context: NSManagedObjectContext) -> User {
          let user = User(context: context)
          user.id = self.id
          user.name = self.name
          user.email = self.email
          user.createdAt = self.createdAt
          user.isActive = self.isActive
          return user
      }
  }
  ```

**Benefits**:

- Domain layer independent of Core Data
- Can change persistence without affecting business logic
- Easier testing with simple Swift structs

---

#### 4.2 **Implement Response Caching Pattern**

**Why**: Template uses sophisticated caching in repositories.

**What to do**:

- [ ] Enhance your existing `CacheManager` to work at repository level
- [ ] Implement cache in repositories:
  ```swift
  // Data/Repositories/DefaultUserRepository.swift
  final class DefaultUserRepository: UserRepository {
      private let coreDataService: UserServiceProtocol
      private let cache: UserResponseStorage

      func fetchUsers() async throws -> [UserDomain] {
          // Check cache first
          if let cached = try? await cache.getUsers() {
              return cached
          }

          // Fetch from Core Data
          let users = try await coreDataService.fetchUsers()
          let domain = users.map { $0.toDomain() }

          // Save to cache
          try? await cache.save(users: domain)

          return domain
      }
  }
  ```

**Benefits**:

- Reduces Core Data queries
- Faster data access
- Better performance

---

### **Priority 5: Testing Improvements** 🟢

#### 5.1 **Add Use Case Tests**

**What to do**:

- [ ] Create `OMOMoneyTests/Domain/UseCases/` directory
- [ ] Test each use case independently:
  ```swift
  // OMOMoneyTests/Domain/UseCases/CreateUserUseCaseTests.swift
  final class CreateUserUseCaseTests: XCTestCase {

      private var mockRepository: MockUserRepository!
      private var useCase: CreateUserUseCase!

      override func setUp() {
          super.setUp()
          mockRepository = MockUserRepository()
          useCase = DefaultCreateUserUseCase(userRepository: mockRepository)
      }

      func testCreateUser_WithValidData_ReturnsUser() async throws {
          // Given
          let name = "Test User"
          let email = "test@example.com"

          // When
          let user = try await useCase.execute(name: name, email: email)

          // Then
          XCTAssertEqual(user.name, name)
          XCTAssertEqual(user.email, email)
          XCTAssertTrue(mockRepository.createUserCalled)
      }

      func testCreateUser_WithEmptyName_ThrowsError() async {
          // Given
          let name = ""
          let email = "test@example.com"

          // When/Then
          do {
              _ = try await useCase.execute(name: name, email: email)
              XCTFail("Expected error to be thrown")
          } catch {
              XCTAssertTrue(error is ValidationError)
          }
      }
  }
  ```

---

#### 5.2 **Add ViewModel Tests with Actions**

**What to do**:

- [ ] Create mock actions:

  ```swift
  // OMOMoneyTests/Presentation/User/UserListViewModelTests.swift
  final class UserListViewModelTests: XCTestCase {

      private var mockUseCase: MockFetchUsersUseCase!
      private var recordedActions: UserListViewModelActionsRecorder!
      private var viewModel: UserListViewModel!

      override func setUp() {
          super.setUp()
          mockUseCase = MockFetchUsersUseCase()
          recordedActions = UserListViewModelActionsRecorder()

          viewModel = UserListViewModel(
              fetchUsersUseCase: mockUseCase,
              actions: recordedActions.actions
          )
      }

      func testDidSelectUser_CallsShowUserDetailsAction() {
          // Given
          let user = UserDomain.mock()

          // When
          viewModel.didSelectUser(user)

          // Then
          XCTAssertTrue(recordedActions.showUserDetailsCalled)
          XCTAssertEqual(recordedActions.selectedUser, user)
      }
  }

  // Test helper
  final class UserListViewModelActionsRecorder {
      var showUserDetailsCalled = false
      var selectedUser: UserDomain?

      lazy var actions: UserListViewModelActions = {
          UserListViewModelActions(
              showUserDetails: { [weak self] user in
                  self?.showUserDetailsCalled = true
                  self?.selectedUser = user
              },
              showCreateUser: {},
              showSettings: {}
          )
      }()
  }
  ```

---

### **Priority 6: UI/UX Improvements** 🔵

#### 6.1 **Implement Custom Observable Pattern**

**Why**: Template uses custom Observable for more control over data binding.

**What to do**:

- [ ] Create custom Observable (similar to template):
  ```swift
  // Presentation/Utils/Observable.swift
  final class Observable<Value> {

      struct Observer<Value> {
          weak var observer: AnyObject?
          let block: (Value) -> Void
      }

      private var observers = [Observer<Value>]()

      var value: Value {
          didSet { notifyObservers() }
      }

      init(_ value: Value) {
          self.value = value
      }

      func observe(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
          observers.append(Observer(observer: observer, block: observerBlock))
          observerBlock(self.value)
      }

      func remove(observer: AnyObject) {
          observers = observers.filter { $0.observer !== observer }
      }

      private func notifyObservers() {
          for observer in observers {
              observer.block(self.value)
          }
      }
  }
  ```
- [ ] Use in ViewModels for granular updates

**Benefits**:

- More control over observation
- Better memory management
- Explicit observer management

---

#### 6.2 **Add Loading States**

**Why**: Template has sophisticated loading state management.

**What to do**:

- [ ] Define loading states:
  ```swift
  // Presentation/Utils/LoadingState.swift
  enum LoadingState {
      case idle
      case loading
      case loadingMore // for pagination
      case loaded
      case failed(Error)
  }
  ```
- [ ] Use in ViewModels:

  ```swift
  @Published var loadingState: LoadingState = .idle

  func loadUsers() async {
      loadingState = .loading

      do {
          let users = try await fetchUsersUseCase.execute()
          self.users = users
          loadingState = .loaded
      } catch {
          loadingState = .failed(error)
      }
  }
  ```

---

### **Priority 7: Additional Enhancements** 🔵

#### 7.1 **Add Cancellable Protocol**

**What to do**:

- [ ] Implement Cancellable protocol:
  ```swift
  // Common/Cancellable.swift
  protocol Cancellable {
      func cancel()
  }
  ```
- [ ] Return cancellable from async operations
- [ ] Allow ViewModels to cancel in-flight requests

---

#### 7.2 **Add Error Handling Extensions**

**What to do**:

- [ ] Create error extensions:
  ```swift
  // Common/ConnectionError.swift
  extension Error {
      var isInternetConnectionError: Bool {
          // Implementation
      }
  }
  ```

---

## 📁 Proposed New Directory Structure

```
OMOMoney/
├── Application/
│   ├── DIContainer/
│   │   ├── AppDIContainer.swift
│   │   ├── UserSceneDIContainer.swift
│   │   ├── GroupSceneDIContainer.swift
│   │   └── EntrySceneDIContainer.swift
│   ├── AppDelegate.swift (if needed)
│   ├── AppFlowCoordinator.swift
│   └── AppConfiguration.swift
│
├── Domain/
│   ├── Entities/
│   │   ├── UserDomain.swift
│   │   ├── GroupDomain.swift
│   │   ├── EntryDomain.swift
│   │   ├── CategoryDomain.swift
│   │   └── ItemDomain.swift
│   ├── UseCases/
│   │   ├── User/
│   │   │   ├── FetchUsersUseCase.swift
│   │   │   ├── CreateUserUseCase.swift
│   │   │   ├── UpdateUserUseCase.swift
│   │   │   └── DeleteUserUseCase.swift
│   │   ├── Group/
│   │   │   ├── FetchGroupsUseCase.swift
│   │   │   └── CreateGroupUseCase.swift
│   │   └── Entry/
│   │       ├── FetchEntriesUseCase.swift
│   │       └── CreateEntryUseCase.swift
│   └── Interfaces/
│       └── Repositories/
│           ├── UserRepository.swift
│           ├── GroupRepository.swift
│           ├── EntryRepository.swift
│           └── CategoryRepository.swift
│
├── Data/
│   ├── Repositories/
│   │   ├── DefaultUserRepository.swift
│   │   ├── DefaultGroupRepository.swift
│   │   └── DefaultEntryRepository.swift
│   └── PersistentStorages/
│       ├── CoreDataStack/
│       │   └── Persistence.swift
│       └── DTOMapping/
│           ├── User+Mapping.swift
│           ├── Group+Mapping.swift
│           └── Entry+Mapping.swift
│
├── Presentation/
│   ├── Flows/
│   │   ├── AppFlowCoordinator.swift
│   │   ├── UserFlowCoordinator.swift
│   │   ├── GroupFlowCoordinator.swift
│   │   └── EntryFlowCoordinator.swift
│   ├── UserScene/
│   │   ├── UserList/
│   │   │   ├── View/
│   │   │   │   └── UserListView.swift
│   │   │   └── ViewModel/
│   │   │       ├── UserListViewModel.swift
│   │   │       └── UserListViewModelActions.swift
│   │   ├── UserDetail/
│   │   └── CreateUser/
│   ├── GroupScene/
│   │   ├── GroupList/
│   │   ├── GroupDetail/
│   │   └── CreateGroup/
│   ├── EntryScene/
│   │   ├── EntryList/
│   │   ├── EntryDetail/
│   │   └── AddEntry/
│   └── Utils/
│       ├── Observable.swift
│       ├── LoadingState.swift
│       └── Extensions/
│
├── Common/
│   ├── Cancellable.swift
│   ├── ConnectionError.swift
│   └── DispatchQueueType.swift
│
├── Services/ (Keep existing for Core Data operations)
│   ├── Protocols/
│   └── Implementation/
│
├── Utilities/
│   ├── Constants/
│   ├── Extensions/
│   └── Helpers/
│
├── Assets.xcassets/
├── OMOMoney.xcdatamodeld/
├── OMOMoneyApp.swift
└── OMOMoney.entitlements
```

---

## 🎯 Implementation Roadmap

### **Phase 1: Domain Layer Foundation** (Week 1-2)

1. Create Domain entities
2. Create repository interfaces
3. Create basic use cases
4. Add DTO mappings

### **Phase 2: Repository Pattern** (Week 3)

1. Implement repositories
2. Update services to work with repositories
3. Add caching at repository level

### **Phase 3: DI Container** (Week 4)

1. Create AppDIContainer
2. Create scene-specific containers
3. Update app entry point

### **Phase 4: Flow Coordinators** (Week 5-6)

1. Implement flow coordinators
2. Add ViewModelActions
3. Update navigation

### **Phase 5: Testing** (Week 7)

1. Add use case tests
2. Add ViewModel tests
3. Add repository tests

### **Phase 6: Polish** (Week 8)

1. Add custom Observable
2. Improve error handling
3. Add loading states

---

## 📊 Comparison Summary

| Aspect                 | Your App              | Template                  | Recommendation                |
| ---------------------- | --------------------- | ------------------------- | ----------------------------- |
| **Architecture**       | MVVM + Services       | Clean Architecture + MVVM | ✅ Adopt layered architecture |
| **Domain Layer**       | ❌ None               | ✅ Present                | ✅ Add Domain layer           |
| **Use Cases**          | ❌ None               | ✅ Present                | ✅ Add Use Cases              |
| **Repository Pattern** | ❌ None               | ✅ Present                | ✅ Add Repositories           |
| **DI Container**       | ⚠️ Basic              | ✅ Centralized            | ✅ Improve DI                 |
| **Flow Coordinators**  | ❌ None               | ✅ Present                | ✅ Add Coordinators           |
| **DTO Pattern**        | ❌ None               | ✅ Present                | ✅ Add DTOs                   |
| **Testing**            | ⚠️ Services only      | ✅ Comprehensive          | ✅ Expand testing             |
| **Swift Concurrency**  | ✅ Modern async/await | ⚠️ Callbacks              | ✅ Keep modern approach       |
| **SwiftUI**            | ✅ iOS 18.5+          | ⚠️ Mixed UIKit            | ✅ Keep SwiftUI               |
| **Caching**            | ✅ Present            | ✅ Present                | ✅ Keep & enhance             |
| **Threading**          | ✅ Good               | ✅ Good                   | ✅ Maintain                   |

---

## 🏆 Final Assessment

### **Your Project Grade: B+ (Very Good)**

**Strengths:**

- ✅ Modern Swift and SwiftUI implementation
- ✅ Good service layer with protocols
- ✅ Proper async/await usage
- ✅ Good testing foundation
- ✅ Caching system in place
- ✅ Proper threading

**Areas for Growth:**

- ⚠️ Missing Clean Architecture layers
- ⚠️ No separation of business logic (Use Cases)
- ⚠️ Tight coupling to Core Data
- ⚠️ Navigation mixed into views
- ⚠️ Limited testability due to coupling

### **After Implementing Recommendations: A+ (Excellent)**

**You will have:**

- ✅ Industry-standard Clean Architecture
- ✅ Highly testable codebase
- ✅ Flexible, maintainable code
- ✅ Clear separation of concerns
- ✅ Easy to scale and extend
- ✅ Modern Swift + Best Practices

---

## 🚀 Quick Wins (Start Here)

These can be implemented quickly for immediate benefit:

1. **Create Domain Entities** (2-3 hours)

   - Simple Swift structs for your main entities
   - No Core Data dependencies

2. **Add One Use Case** (1-2 hours)

   - Start with `FetchUsersUseCase`
   - Extract from ViewModel

3. **Create One Repository** (2-3 hours)

   - `DefaultUserRepository`
   - Wrap existing service

4. **Add ViewModelActions** (1-2 hours)

   - For one ViewModel (e.g., UserListViewModel)
   - Decouple navigation

5. **Create Basic DI Container** (2-3 hours)
   - `AppDIContainer` with existing services
   - Centralize dependencies

**Total: 8-13 hours for foundational improvements**

---

## 📚 Resources

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [iOS Clean Architecture MVVM Template](https://github.com/kudoleh/iOS-Clean-Architecture-MVVM)
- [Advanced iOS App Architecture](https://www.raywenderlich.com/8477-introducing-advanced-ios-app-architecture)
- [SOLID Principles in Swift](https://marcosantadev.com/solid-principles-applied-swift/)

---

**Generated:** November 17, 2025  
**For Project:** OMOMoney  
**Based on:** iOS-Clean-Architecture-MVVM Template Analysis
