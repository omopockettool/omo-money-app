# Clean Architecture Implementation Guide

## 🎉 What Was Implemented

This document outlines the Clean Architecture improvements implemented in the OMOMoney project based on iOS Clean Architecture MVVM best practices.

---

## 📁 New Directory Structure

```
OMOMoney/
├── Domain/                          ✅ NEW - Business Logic Layer
│   ├── Entities/                    ✅ Pure Swift domain models
│   │   ├── UserDomain.swift
│   │   ├── GroupDomain.swift
│   │   ├── CategoryDomain.swift
│   │   ├── PaymentMethodDomain.swift
│   │   ├── ItemListDomain.swift
│   │   ├── ItemDomain.swift
│   │   └── UserGroupDomain.swift
│   ├── UseCases/                    ✅ Business operations
│   │   ├── User/
│   │   │   ├── FetchUsersUseCase.swift
│   │   │   ├── CreateUserUseCase.swift
│   │   │   ├── UpdateUserUseCase.swift
│   │   │   ├── DeleteUserUseCase.swift
│   │   │   └── SearchUsersUseCase.swift
│   │   └── Group/
│   │       ├── FetchGroupsUseCase.swift
│   │       ├── CreateGroupUseCase.swift
│   │       ├── UpdateGroupUseCase.swift
│   │       └── DeleteGroupUseCase.swift
│   └── Interfaces/                  ✅ Repository protocols
│       └── Repositories/
│           ├── UserRepository.swift
│           ├── GroupRepository.swift
│           ├── CategoryRepository.swift
│           ├── PaymentMethodRepository.swift
│           ├── ItemListRepository.swift
│           ├── ItemRepository.swift
│           └── UserGroupRepository.swift
│
├── Data/                            ✅ NEW - Data Layer
│   ├── Repositories/                ✅ Repository implementations
│   │   ├── DefaultUserRepository.swift
│   │   └── DefaultGroupRepository.swift
│   └── PersistentStorages/          ✅ DTO mappings
│       └── DTOMapping/
│           ├── User+Mapping.swift
│           ├── Group+Mapping.swift
│           ├── Category+Mapping.swift
│           ├── PaymentMethod+Mapping.swift
│           ├── ItemList+Mapping.swift
│           ├── Item+Mapping.swift
│           └── UserGroup+Mapping.swift
│
├── Application/                     ✅ NEW - App-level configuration
│   └── DIContainer/                 ✅ Dependency Injection
│       ├── AppDIContainer.swift
│       ├── UserSceneDIContainer.swift
│       └── GroupSceneDIContainer.swift
│
├── Services/                        ✅ Existing - kept as-is
│   ├── Protocols/
│   └── Implementation/
│
└── OMOMoneyTests/                   ✅ NEW - Test infrastructure
    ├── Domain/
    │   └── UseCases/
    │       └── CreateUserUseCaseTests.swift
    └── Mocks/
        ├── MockUserRepository.swift
        └── MockGroupRepository.swift
```

---

## ✅ Implementation Summary

### 1. Domain Layer (✅ Complete)

**Domain Entities** - Pure Swift models with no Core Data dependencies:
- `UserDomain` - User business model with validation
- `GroupDomain` - Group business model
- `CategoryDomain` - Category with budget limits
- `PaymentMethodDomain` - Payment methods
- `ItemListDomain` - Transaction entries
- `ItemDomain` - Individual items in transactions
- `UserGroupDomain` - User-group relationships with roles

**Features:**
- ✅ Identifiable, Equatable, Hashable conformance
- ✅ Built-in validation methods
- ✅ Mock data helpers for testing
- ✅ No Core Data dependencies
- ✅ Computed properties (e.g., `totalAmount` in ItemDomain)

---

### 2. Repository Pattern (✅ Complete)

**Repository Protocols** - Abstraction of data operations:
- `UserRepository` - User CRUD operations
- `GroupRepository` - Group CRUD operations
- `CategoryRepository` - Category management
- `PaymentMethodRepository` - Payment method management
- `ItemListRepository` - Transaction management
- `ItemRepository` - Item management
- `UserGroupRepository` - User-group relationship management

**Repository Implementations:**
- `DefaultUserRepository` - Wraps UserService
- `DefaultGroupRepository` - Wraps GroupService

**Features:**
- ✅ Protocol-based abstraction
- ✅ Async/await support
- ✅ Clean separation from Core Data
- ✅ Easy to swap implementations
- ✅ Testable with mock repositories

---

### 3. DTO Mapping (✅ Complete)

**Bidirectional mappings** between Core Data entities and Domain models:
- `User+Mapping.swift`
- `Group+Mapping.swift`
- `Category+Mapping.swift`
- `PaymentMethod+Mapping.swift`
- `ItemList+Mapping.swift`
- `Item+Mapping.swift`
- `UserGroup+Mapping.swift`

**Features:**
- ✅ `toDomain()` - Convert Core Data to Domain
- ✅ `toCoreData(context:)` - Convert Domain to Core Data
- ✅ `update(from:)` - Update existing Core Data entities
- ✅ Automatic timestamp handling

---

### 4. Use Cases (✅ Complete)

**User Use Cases:**
- `FetchUsersUseCase` - Retrieve all users with validation
- `CreateUserUseCase` - Create user with business validation
- `UpdateUserUseCase` - Update user with validation
- `DeleteUserUseCase` - Delete user
- `SearchUsersUseCase` - Search users by name/email

**Group Use Cases:**
- `FetchGroupsUseCase` - Retrieve groups (all or by user)
- `CreateGroupUseCase` - Create group with validation
- `UpdateGroupUseCase` - Update group with validation
- `DeleteGroupUseCase` - Delete group

**Features:**
- ✅ Single Responsibility Principle
- ✅ Business logic encapsulation
- ✅ Input validation and sanitization
- ✅ Protocol + Implementation pattern
- ✅ Easy to test independently
- ✅ Reusable across ViewModels

---

### 5. Dependency Injection Container (✅ Complete)

**AppDIContainer** - Main application container:
- Manages Core Data stack
- Creates and provides Services
- Creates and provides Repositories
- Factory methods for scene containers

**Scene-specific containers:**
- `UserSceneDIContainer` - User feature dependencies
- `GroupSceneDIContainer` - Group feature dependencies

**Features:**
- ✅ Singleton pattern for app container
- ✅ Lazy initialization
- ✅ Centralized dependency management
- ✅ Scene-specific dependency scoping
- ✅ Factory methods for Use Cases
- ✅ Easy to extend for new features

---

### 6. Testing Infrastructure (✅ Started)

**Mock Repositories:**
- `MockUserRepository` - Tracks calls and returns test data
- `MockGroupRepository` - Tracks calls and returns test data

**Use Case Tests:**
- `CreateUserUseCaseTests` - Comprehensive validation tests

**Features:**
- ✅ Call tracking for verification
- ✅ Configurable mock data
- ✅ Error injection for edge cases
- ✅ Reset functionality for clean tests
- ✅ Async/await test support

---

## 🎯 How To Use

### Using Use Cases in ViewModels

```swift
import Foundation

@MainActor
final class UserListViewModel: ObservableObject {
    
    @Published var users: [UserDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Use Cases injected via DI Container
    private let fetchUsersUseCase: FetchUsersUseCase
    private let deleteUserUseCase: DeleteUserUseCase
    
    init(
        fetchUsersUseCase: FetchUsersUseCase,
        deleteUserUseCase: DeleteUserUseCase
    ) {
        self.fetchUsersUseCase = fetchUsersUseCase
        self.deleteUserUseCase = deleteUserUseCase
    }
    
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            users = try await fetchUsersUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteUser(id: UUID) async {
        do {
            try await deleteUserUseCase.execute(userId: id)
            await loadUsers() // Refresh list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Creating ViewModels with DI Container

```swift
// In your View or App
let appContainer = AppDIContainer.shared
let userSceneContainer = appContainer.makeUserSceneDIContainer()

let viewModel = UserListViewModel(
    fetchUsersUseCase: userSceneContainer.makeFetchUsersUseCase(),
    deleteUserUseCase: userSceneContainer.makeDeleteUserUseCase()
)
```

### Working with Domain Models

```swift
// Create a new user
let user = UserDomain(
    name: "John Doe",
    email: "john@example.com"
)

// Validate
try user.validate()

// Use in Use Case
let createdUser = try await createUserUseCase.execute(
    name: user.name,
    email: user.email
)
```

---

## 🧪 Testing Use Cases

```swift
import XCTest
@testable import OMOMoney

final class FetchUsersUseCaseTests: XCTestCase {
    
    func testFetchUsers_Success() async throws {
        // Given
        let mockRepo = MockUserRepository()
        mockRepo.usersToReturn = [
            .mock(name: "User 1"),
            .mock(name: "User 2")
        ]
        let useCase = DefaultFetchUsersUseCase(userRepository: mockRepo)
        
        // When
        let users = try await useCase.execute()
        
        // Then
        XCTAssertTrue(mockRepo.fetchUsersCalled)
        XCTAssertEqual(users.count, 2)
    }
}
```

---

## 📊 Benefits Achieved

### ✅ Separation of Concerns
- Business logic (Domain) independent of infrastructure (Data)
- ViewModels focus only on presentation
- Use Cases encapsulate single operations

### ✅ Testability
- Mock repositories for testing Use Cases
- No Core Data dependencies in tests
- Fast, isolated unit tests

### ✅ Flexibility
- Easy to swap Core Data for different persistence
- Can add API repositories alongside Core Data
- Repository pattern abstracts implementation

### ✅ Maintainability
- Clear project structure
- Single Responsibility Principle
- Easy to locate and modify code

### ✅ Reusability
- Use Cases can be reused across features
- Domain models are pure Swift
- Repository protocols enable multiple implementations

---

## 🚀 Next Steps

### Priority 1: Complete Repository Implementations
- [ ] Implement remaining repositories (Category, PaymentMethod, ItemList, Item, UserGroup)
- [ ] Add caching at repository level
- [ ] Implement batch operations

### Priority 2: Refactor ViewModels
- [ ] Update UserListViewModel to use Use Cases
- [ ] Update GroupListViewModel to use Use Cases
- [ ] Add ViewModelActions pattern for navigation
- [ ] Remove direct Service dependencies from ViewModels

### Priority 3: Expand Use Cases
- [ ] Create Category Use Cases
- [ ] Create PaymentMethod Use Cases
- [ ] Create ItemList/Item Use Cases
- [ ] Add complex business operations (e.g., CalculateTotalExpensesUseCase)

### Priority 4: Implement Flow Coordinators
- [ ] Create UserFlowCoordinator
- [ ] Create GroupFlowCoordinator
- [ ] Implement ViewModelActions pattern
- [ ] Decouple navigation from Views

### Priority 5: Expand Testing
- [ ] Add tests for all Use Cases
- [ ] Add ViewModel tests with mock Use Cases
- [ ] Add Repository tests
- [ ] Add integration tests

### Priority 6: Add Common Utilities
- [ ] LoadingState enum
- [ ] Custom Observable pattern
- [ ] Cancellable protocol
- [ ] Error handling extensions

---

## 📚 Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Views, ViewModels) - SwiftUI/UIKit    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│  (Entities, Use Cases, Repositories)    │
│  - Pure Swift, No frameworks            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  (Repository Impl, DTO Mapping)         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│    Infrastructure Layer                 │
│  (Core Data, Services, Network)         │
└─────────────────────────────────────────┘
```

**Dependency Rule:** 
- Inner layers know nothing about outer layers
- Domain layer has NO dependencies
- Data layer depends on Domain
- Presentation depends on Domain (not on Data directly)

---

## 🎓 Key Concepts

### Domain Entities
Pure Swift models representing business concepts, with no external dependencies.

### Use Cases
Single-purpose operations containing business logic, validated and executed through repositories.

### Repositories
Abstraction of data sources, providing a clean interface for data operations without exposing implementation details.

### DTO Mapping
Translation layer between Core Data entities and Domain models, keeping layers decoupled.

### Dependency Injection
Centralized creation and management of dependencies, enabling testability and flexibility.

---

**Implementation Date:** November 18, 2025  
**Status:** ✅ Foundation Complete  
**Next Phase:** ViewModel Refactoring & Expanded Testing

