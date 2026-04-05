# Clean Architecture in OMOMoney

## Overview

OMOMoney follows **Clean Architecture** principles, ensuring separation of concerns, testability, and maintainability. This document explains the architecture layers and how they interact.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│         (App Entry, DI Containers, Configuration)        │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│Presentation │◄───│   Domain    │───►│    Data     │
│   Layer     │    │   Layer     │    │   Layer     │
└─────────────┘    └─────────────┘    └─────────────┘
        │                  ▲                  │
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                ┌──────────────────┐
                │  Infrastructure  │
                │     Layer        │
                └──────────────────┘
```

### Dependency Rule
**Dependencies point inward**: Outer layers depend on inner layers, never the reverse.
- ✅ Presentation → Domain
- ✅ Data → Domain
- ✅ Presentation → Infrastructure
- ❌ Domain → Data (NOT ALLOWED)
- ❌ Domain → Presentation (NOT ALLOWED)

---

## 1. Domain Layer (Business Logic)

**Location**: `/Domain`

**Purpose**: Contains all business logic, entities, and rules. No dependencies on frameworks or external libraries.

### Structure
```
Domain/
├── Entities/
│   ├── UserDomain.swift
│   ├── GroupDomain.swift
│   └── ItemListDomain.swift
│
├── Protocols/
│   ├── Repositories/
│   │   ├── UserRepository.swift
│   │   └── GroupRepository.swift
│   └── Services/
│       ├── UserServiceProtocol.swift
│       └── GroupServiceProtocol.swift
│
├── UseCases/
│   ├── User/
│   │   └── CreateUserUseCase.swift
│   └── Group/
│       └── CreateGroupUseCase.swift
│
└── Errors/
    ├── RepositoryError.swift
    └── ValidationError.swift
```

### Components

#### 1.1 Entities (Domain Models)
Plain Swift structs/classes representing business concepts.

```swift
// Domain/Entities/UserDomain.swift
struct UserDomain {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
    let lastModifiedAt: Date
}
```

**Rules**:
- ✅ Pure Swift types
- ✅ Immutable when possible (use `let`)
- ✅ No framework dependencies (no CoreData, no SwiftUI)
- ❌ No business logic in entities (move to use cases)

#### 1.2 Protocols

##### Repository Protocols
Define data access contracts without implementation details.

```swift
// Domain/Protocols/Repositories/UserRepository.swift
protocol UserRepository {
    func fetchUsers() async throws -> [UserDomain]
    func fetchUser(id: UUID) async throws -> UserDomain?
    func createUser(name: String, email: String) async throws -> UserDomain
    func updateUser(_ user: UserDomain) async throws
    func deleteUser(id: UUID) async throws
}
```

##### Service Protocols
Define infrastructure service contracts.

```swift
// Domain/Protocols/Services/UserServiceProtocol.swift
protocol UserServiceProtocol {
    func fetchUser(by id: UUID) async throws -> User?
    func createUser(name: String, email: String) async throws -> User
    // Core Data specific operations
}
```

**Why separate Repository and Service protocols?**
- **Repository**: Domain-level abstraction (works with Domain models)
- **Service**: Data-level abstraction (works with Core Data entities)
- **Repository uses Service**: Repository implements domain protocol using service

#### 1.3 Use Cases (Interactors)
Encapsulate business logic for specific operations.

```swift
// Domain/UseCases/User/CreateUserUseCase.swift
protocol CreateUserUseCase {
    func execute(name: String, email: String) async throws -> UserDomain
}

final class DefaultCreateUserUseCase: CreateUserUseCase {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    func execute(name: String, email: String) async throws -> UserDomain {
        // 1. Validate input
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        
        guard email.contains("@") else {
            throw ValidationError.invalidEmail
        }
        
        // 2. Business logic
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 3. Call repository
        return try await userRepository.createUser(
            name: trimmedName, 
            email: trimmedEmail
        )
    }
}
```

**Use Case Guidelines**:
- ✅ One use case per business operation
- ✅ Protocol + Default implementation
- ✅ Single Responsibility Principle
- ✅ All business validation here
- ❌ No UI logic
- ❌ No data source details

#### 1.4 Errors
Domain-specific errors.

```swift
// Domain/Errors/ValidationError.swift
enum ValidationError: Error, LocalizedError {
    case emptyName
    case emptyEmail
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name cannot be empty"
        case .emptyEmail:
            return "Email cannot be empty"
        case .invalidEmail:
            return "Invalid email format"
        }
    }
}
```

---

## 2. Data Layer (Implementation Details)

**Location**: `/Data`

**Purpose**: Implements data access. Handles Core Data, API calls, local storage, etc.

### Structure
```
Data/
├── CoreData/
│   ├── PersistenceController.swift
│   ├── OMOMoney.xcdatamodeld
│   └── Entities/
│       ├── User+CoreDataClass.swift
│       └── User+CoreDataProperties.swift
│
├── Repositories/
│   └── DefaultUserRepository.swift
│
└── Services/
    ├── CoreDataService.swift (Base)
    └── UserService.swift
```

### Components

#### 2.1 Core Data Entities
Generated by Core Data, managed by Xcode.

```swift
// Data/CoreData/Entities/User+CoreDataClass.swift
@objc(User)
public class User: NSManagedObject {
    // Managed by Core Data
}

// User+CoreDataProperties.swift
extension User {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String
    // ...
}
```

#### 2.2 Services
Handle Core Data operations, provide CRUD functionality.

```swift
// Data/Services/UserService.swift
final class UserService: CoreDataService, UserServiceProtocol {
    
    func fetchUser(by id: UUID) async throws -> User? {
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try await fetch(request)
        return results.first
    }
    
    func createUser(name: String, email: String) async throws -> User {
        return try await context.perform {
            let user = User(context: self.context)
            user.id = UUID()
            user.name = name
            user.email = email
            user.createdAt = Date()
            user.lastModifiedAt = Date()
            try self.context.save()
            return user
        }
    }
}
```

**Service Guidelines**:
- ✅ Extends `CoreDataService` base class
- ✅ Implements service protocol from Domain
- ✅ Works with Core Data entities
- ✅ Handles threading (async/await)
- ❌ No business logic (that's in use cases)

#### 2.3 Repositories
Bridge between Domain and Data layers.

```swift
// Data/Repositories/DefaultUserRepository.swift
final class DefaultUserRepository: UserRepository {
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    func fetchUsers() async throws -> [UserDomain] {
        let users = try await userService.fetchUsers()
        return users.map { $0.toDomain() }
    }
    
    func createUser(name: String, email: String) async throws -> UserDomain {
        let user = try await userService.createUser(name: name, email: email)
        return user.toDomain()
    }
}
```

**Repository Guidelines**:
- ✅ Implements Repository protocol from Domain
- ✅ Uses Service to access data
- ✅ Converts Core Data entities → Domain models
- ✅ Converts Domain models → Core Data entities
- ❌ No business logic

#### 2.4 Entity Extensions (Mappers)
Convert between Core Data and Domain models.

```swift
// Data/CoreData/Entities/User+CoreDataClass.swift
extension User {
    func toDomain() -> UserDomain {
        return UserDomain(
            id: self.id,
            name: self.name,
            email: self.email,
            createdAt: self.createdAt,
            lastModifiedAt: self.lastModifiedAt
        )
    }
    
    func updateFromDomain(_ domain: UserDomain) {
        self.name = domain.name
        self.email = domain.email
        self.lastModifiedAt = Date()
    }
}
```

---

## 3. Presentation Layer (UI)

**Location**: `/Presentation`

**Purpose**: Handles user interface, user interactions, and view logic.

### Structure
```
Presentation/
├── Scenes/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   └── User/
│       ├── CreateUserView.swift
│       └── CreateUserViewModel.swift
│
└── Common/
    ├── Views/
    └── Components/
```

### Components

#### 3.1 Views (SwiftUI)
UI components, no business logic.

```swift
// Presentation/Scenes/User/CreateUserView.swift
struct CreateUserView: View {
    @StateObject private var viewModel: CreateUserViewModel
    
    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Email", text: $viewModel.email)
            
            Button("Create User") {
                Task {
                    await viewModel.createUser()
                }
            }
            .disabled(!viewModel.canSave)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
```

**View Guidelines**:
- ✅ SwiftUI views
- ✅ Observe ViewModel
- ✅ Handle user interactions
- ✅ Display data from ViewModel
- ❌ No business logic
- ❌ No direct data access

#### 3.2 ViewModels
Presentation logic, state management.

```swift
// Presentation/Scenes/User/CreateUserViewModel.swift
@MainActor
final class CreateUserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let createUserUseCase: CreateUserUseCase
    
    init(createUserUseCase: CreateUserUseCase) {
        self.createUserUseCase = createUserUseCase
    }
    
    var canSave: Bool {
        !name.isEmpty && !email.isEmpty
    }
    
    func createUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await createUserUseCase.execute(
                name: name,
                email: email
            )
            // Success handling
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
```

**ViewModel Guidelines**:
- ✅ `@MainActor` for UI updates
- ✅ `ObservableObject` with `@Published` properties
- ✅ Uses Use Cases (not repositories directly)
- ✅ Handles presentation state (loading, errors)
- ✅ Input validation (UI level)
- ❌ No Core Data imports
- ❌ No business logic (delegate to use cases)

---

## 4. Infrastructure Layer (Cross-Cutting Concerns)

**Location**: `/Infrastructure`

**Purpose**: Utilities, helpers, extensions used across layers.

### Structure
```
Infrastructure/
├── Cache/
│   └── CacheManager.swift
├── Helpers/
│   └── DateFormatterHelper.swift
├── Utils/
│   └── DataPreloader.swift
└── Extensions/
    └── Date+Extensions.swift
```

### Components

#### 4.1 Cache
```swift
// Infrastructure/Cache/CacheManager.swift
@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    func cacheData<T>(_ data: T, for key: String) { }
    func getCachedData<T>(for key: String) -> T? { }
}
```

#### 4.2 Helpers
```swift
// Infrastructure/Helpers/DateFormatterHelper.swift
struct DateFormatterHelper {
    static let shared = DateFormatterHelper()
    
    func format(_ date: Date, style: DateFormatter.Style) -> String {
        // ...
    }
}
```

---

## 5. Application Layer (Configuration)

**Location**: `/Application`

**Purpose**: App entry point, dependency injection, configuration.

### Structure
```
Application/
├── OmoMoneyApp.swift
└── DI/
    ├── AppDIContainer.swift
    ├── UserSceneDIContainer.swift
    └── GroupSceneDIContainer.swift
```

### Components

#### 5.1 App Entry Point
```swift
// Application/OmoMoneyApp.swift
@main
struct OmoMoneyApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

#### 5.2 Dependency Injection Container
```swift
// Application/DI/AppDIContainer.swift
final class AppDIContainer {
    static let shared = AppDIContainer()
    
    // Core Data
    lazy var persistenceController: PersistenceController = {
        PersistenceController.shared
    }()
    
    // Services
    lazy var userService: UserServiceProtocol = {
        UserService(context: persistenceController.container.viewContext)
    }()
    
    // Repositories
    lazy var userRepository: UserRepository = {
        DefaultUserRepository(userService: userService)
    }()
    
    // Scene Containers
    func makeUserSceneDIContainer() -> UserSceneDIContainer {
        UserSceneDIContainer(dependencies: .init(
            userRepository: userRepository
        ))
    }
}
```

#### 5.3 Scene DI Container
```swift
// Application/DI/UserSceneDIContainer.swift
final class UserSceneDIContainer {
    struct Dependencies {
        let userRepository: UserRepository
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // Use Cases
    func makeCreateUserUseCase() -> CreateUserUseCase {
        DefaultCreateUserUseCase(userRepository: dependencies.userRepository)
    }
    
    // ViewModels
    func makeCreateUserViewModel() -> CreateUserViewModel {
        CreateUserViewModel(createUserUseCase: makeCreateUserUseCase())
    }
}
```

---

## Data Flow Example

Let's trace a "Create User" operation through all layers:

### 1. User Interaction (Presentation Layer)
```swift
// User taps "Create" button in CreateUserView
Button("Create User") {
    Task {
        await viewModel.createUser()
    }
}
```

### 2. ViewModel (Presentation Layer)
```swift
// CreateUserViewModel
func createUser() async {
    isLoading = true
    do {
        // Call use case
        let user = try await createUserUseCase.execute(
            name: name,
            email: email
        )
        // Update UI state
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

### 3. Use Case (Domain Layer)
```swift
// DefaultCreateUserUseCase
func execute(name: String, email: String) async throws -> UserDomain {
    // Validate
    guard !name.isEmpty else {
        throw ValidationError.emptyName
    }
    
    // Business logic
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    
    // Call repository
    return try await userRepository.createUser(
        name: trimmedName,
        email: email
    )
}
```

### 4. Repository (Data Layer)
```swift
// DefaultUserRepository
func createUser(name: String, email: String) async throws -> UserDomain {
    // Call service
    let user = try await userService.createUser(name: name, email: email)
    
    // Convert to domain model
    return user.toDomain()
}
```

### 5. Service (Data Layer)
```swift
// UserService
func createUser(name: String, email: String) async throws -> User {
    return try await context.perform {
        let user = User(context: self.context)
        user.id = UUID()
        user.name = name
        user.email = email
        user.createdAt = Date()
        try self.context.save()
        return user
    }
}
```

### 6. Response Flow (Back Up)
```
Core Data Entity (User)
    ↓ toDomain()
Domain Model (UserDomain)
    ↓ return
Use Case
    ↓ return
ViewModel
    ↓ @Published update
View
    ↓ UI refresh
User sees new user
```

---

## Testing Strategy

### Domain Layer Tests
```swift
// Tests/DomainTests/UseCases/CreateUserUseCaseTests.swift
@Test("Create user with valid data")
func createUserSuccess() async throws {
    // Arrange
    let mockRepository = MockUserRepository()
    let useCase = DefaultCreateUserUseCase(userRepository: mockRepository)
    
    // Act
    let user = try await useCase.execute(name: "John", email: "john@example.com")
    
    // Assert
    #expect(user.name == "John")
    #expect(user.email == "john@example.com")
}
```

### Data Layer Tests
```swift
// Tests/DataTests/Services/UserServiceTests.swift
@Test("Create user in Core Data")
func createUser() async throws {
    let context = PersistenceController.preview.container.viewContext
    let service = UserService(context: context)
    
    let user = try await service.createUser(name: "Test", email: "test@example.com")
    
    #expect(user.name == "Test")
    #expect(user.id != nil)
}
```

### Presentation Layer Tests
```swift
// Tests/PresentationTests/ViewModels/CreateUserViewModelTests.swift
@Test("ViewModel creates user successfully")
func createUserSuccess() async throws {
    let mockUseCase = MockCreateUserUseCase()
    let viewModel = CreateUserViewModel(createUserUseCase: mockUseCase)
    
    viewModel.name = "John"
    viewModel.email = "john@example.com"
    
    await viewModel.createUser()
    
    #expect(viewModel.showError == false)
    #expect(mockUseCase.executeCallCount == 1)
}
```

---

## Best Practices

### ✅ DO

1. **Keep Domain Pure**
   - No framework imports (except Foundation)
   - No Core Data, SwiftUI, or UIKit

2. **Use Protocols for Abstraction**
   - Repository protocols in Domain
   - Service protocols in Domain
   - Use case protocols in Domain

3. **Dependency Injection**
   - Always inject dependencies
   - Use DI containers
   - Don't use singletons for business logic

4. **Async/Await**
   - Prefer async/await over completion handlers
   - Use `@MainActor` for ViewModels
   - Proper error handling with `try`/`catch`

5. **Testing**
   - Test each layer independently
   - Mock dependencies
   - Use Swift Testing framework

### ❌ DON'T

1. **Don't Mix Layers**
   - No Core Data in ViewModels
   - No SwiftUI in Use Cases
   - No business logic in Views

2. **Don't Skip Layers**
   - ViewModel should not call Repository directly
   - View should not call Use Case directly
   - Always go through proper channels

3. **Don't Use God Objects**
   - Keep classes focused
   - Single Responsibility Principle
   - Break down large files

4. **Don't Ignore Errors**
   - Handle errors at appropriate layer
   - Provide meaningful error messages
   - Log errors for debugging

---

## Benefits of This Architecture

1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Changes are isolated to specific layers
3. **Scalability**: Easy to add features without affecting existing code
4. **Flexibility**: Can swap implementations (e.g., Core Data → Realm)
5. **Team Collaboration**: Clear boundaries for different team members
6. **Reusability**: Use cases can be reused across different UI screens
7. **Independence**: UI, Database, Framework can be changed independently

---

## Quick Reference

| Layer | Purpose | Examples | Imports Allowed |
|-------|---------|----------|----------------|
| **Domain** | Business logic | Entities, Use Cases, Protocols | Foundation only |
| **Data** | Data access | Services, Repositories, Core Data | CoreData, Foundation |
| **Presentation** | UI | Views, ViewModels | SwiftUI, Foundation |
| **Infrastructure** | Utilities | Cache, Helpers, Extensions | Any |
| **Application** | Config | DI Containers, App entry | Any |

---

## File Naming Conventions

- **Domain Entities**: `UserDomain.swift`, `GroupDomain.swift`
- **Protocols**: `UserRepository.swift`, `UserServiceProtocol.swift`
- **Use Cases**: `CreateUserUseCase.swift` (protocol + implementation in same file)
- **Implementations**: `DefaultUserRepository.swift`, `UserService.swift`
- **Core Data**: `User+CoreDataClass.swift`, `User+CoreDataProperties.swift`
- **Views**: `CreateUserView.swift`
- **ViewModels**: `CreateUserViewModel.swift`

---

## Additional Resources

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [iOS Clean Architecture Guide](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-in-swift/)

---

**Last Updated**: November 27, 2025
