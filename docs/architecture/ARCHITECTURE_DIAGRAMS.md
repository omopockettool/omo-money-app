# OMOMoney Architecture Diagrams

## 1. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                         │
│                         (SwiftUI)                             │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │    Views    │  │  ViewModels │  │   Protocols │         │
│  │  (SwiftUI)  │  │ (@MainActor)│  │  (Updates)  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                       DOMAIN LAYER                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Protocols                          │   │
│  │  ┌──────────────┐           ┌──────────────┐        │   │
│  │  │ Repositories │           │   Services   │        │   │
│  │  └──────────────┘           └──────────────┘        │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Entities   │  │  Use Cases   │  │    Errors    │     │
│  │   (Domain)   │  │ (Interactors)│  │ (Validation) │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                        DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Repositories │  │   Services   │  │  Core Data   │      │
│  │    (Impl)    │  │    (Impl)    │  │   Entities   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Cache   │  │ Helpers  │  │  Utils   │  │Extensions│    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└───────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                     APPLICATION LAYER                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │          Dependency Injection Containers             │    │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │    │
│  │  │    App     │  │   User     │  │   Group    │    │    │
│  │  │ Container  │  │  Scene DI  │  │  Scene DI  │    │    │
│  │  └────────────┘  └────────────┘  └────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

---

## 2. Dependency Flow

```
┌─────────────┐
│Presentation │ ──────┐
└─────────────┘       │
                      ▼
┌─────────────┐    ┌────────┐
│    Data     │───►│ Domain │ (Pure Business Logic)
└─────────────┘    └────────┘
                      ▲
┌─────────────┐       │
│Infrastructure│──────┘
└─────────────┘

Rule: Arrows always point TOWARD the Domain layer
- Domain has NO dependencies
- All other layers depend ON Domain
```

---

## 3. Create User Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User taps "Create User" button                           │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 2. CreateUserView                                           │
│    - Captures user input (name, email)                      │
│    - Validates form fields (not empty)                      │
│    - Calls: await viewModel.createUser()                    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 3. CreateUserViewModel (@MainActor)                         │
│    - Sets isLoading = true                                  │
│    - Calls: await createUserUseCase.execute(name, email)    │
│    - Handles success/error                                  │
│    - Updates @Published properties                          │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 4. DefaultCreateUserUseCase                                 │
│    - Validates business rules:                              │
│      • Name not empty                                       │
│      • Email contains "@"                                   │
│      • Trims whitespace                                     │
│    - Calls: await userRepository.createUser(name, email)    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 5. DefaultUserRepository                                    │
│    - Calls: await userService.createUser(name, email)       │
│    - Converts: User → UserDomain                            │
│    - Returns: UserDomain                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 6. UserService                                              │
│    - Creates Core Data entity:                              │
│      let user = User(context: context)                      │
│      user.id = UUID()                                       │
│      user.name = name                                       │
│      user.email = email                                     │
│    - Saves: try context.save()                              │
│    - Returns: User (Core Data entity)                       │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 7. Core Data                                                │
│    - Persists user to SQLite database                       │
│    - Returns saved entity                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ (Response flows back up)
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 8. User (Core Data) → toDomain() → UserDomain               │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 9. ViewModel updates @Published properties                  │
│    - isLoading = false                                      │
│    - Success state                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ 10. View refreshes                                          │
│     - Shows success message                                 │
│     - Dismisses form                                        │
│     - Updates user list                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Layer Interaction Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  View ──────► ViewModel                                     │
│              (uses)│                                         │
│                    │                                         │
│                    ▼                                         │
│              Use Case (Protocol)                            │
│                                                              │
└──────────────────────┬──────────────────────────────────────┘
                       │ implements
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                      DOMAIN LAYER                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Use Case (Impl) ──────► Repository (Protocol)              │
│                                │                             │
│                                │                             │
│  Domain Models ◄───────────────┘                            │
│  (UserDomain, etc)                                          │
│                                                              │
└──────────────────────┬──────────────────────────────────────┘
                       │ implements
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                       DATA LAYER                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Repository (Impl) ──────► Service (Protocol)               │
│         │                           │                        │
│         │                           │                        │
│         │          Service (Impl) ◄─┘                        │
│         │                 │                                  │
│         │                 ▼                                  │
│         │          Core Data Entities                        │
│         │          (User, Group, etc)                        │
│         │                 │                                  │
│         └─────────────────┘                                  │
│              Mapping: Entity ↔ Domain                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. File Organization Tree

```
OMOMoney/
│
├── 📱 Application/                    # App configuration & DI
│   ├── OmoMoneyApp.swift             # App entry point
│   └── DI/
│       ├── AppDIContainer.swift       # Main DI container
│       ├── UserSceneDIContainer.swift # User feature DI
│       └── GroupSceneDIContainer.swift# Group feature DI
│
├── 🏛️ Domain/                         # Business logic (Pure Swift)
│   ├── Entities/                      # Domain models
│   │   ├── UserDomain.swift
│   │   ├── GroupDomain.swift
│   │   └── ItemListDomain.swift
│   │
│   ├── Protocols/                     # Contracts (Interfaces)
│   │   ├── Repositories/              # Data access contracts
│   │   │   ├── UserRepository.swift
│   │   │   ├── GroupRepository.swift
│   │   │   └── ItemListRepository.swift
│   │   │
│   │   └── Services/                  # Service contracts
│   │       ├── UserServiceProtocol.swift
│   │       ├── GroupServiceProtocol.swift
│   │       └── ItemListServiceProtocol.swift
│   │
│   ├── UseCases/                      # Business operations
│   │   ├── User/
│   │   │   ├── CreateUserUseCase.swift
│   │   │   ├── FetchUsersUseCase.swift
│   │   │   └── DeleteUserUseCase.swift
│   │   │
│   │   ├── Group/
│   │   │   ├── CreateGroupUseCase.swift
│   │   │   └── FetchGroupsUseCase.swift
│   │   │
│   │   └── ItemList/
│   │       ├── CreateItemListUseCase.swift
│   │       └── FetchItemListsUseCase.swift
│   │
│   └── Errors/                        # Business errors
│       ├── RepositoryError.swift
│       └── ValidationError.swift
│
├── 💾 Data/                           # Data persistence & access
│   ├── CoreData/
│   │   ├── PersistenceController.swift
│   │   ├── OMOMoney.xcdatamodeld
│   │   └── Entities/                  # Core Data entities
│   │       ├── User+CoreDataClass.swift
│   │       ├── User+CoreDataProperties.swift
│   │       ├── Group+CoreDataClass.swift
│   │       └── ItemList+CoreDataClass.swift
│   │
│   ├── Repositories/                  # Repository implementations
│   │   ├── DefaultUserRepository.swift
│   │   ├── DefaultGroupRepository.swift
│   │   └── DefaultItemListRepository.swift
│   │
│   └── Services/                      # Service implementations
│       ├── CoreDataService.swift      # Base service class
│       ├── UserService.swift
│       ├── GroupService.swift
│       └── ItemListService.swift
│
├── 🎨 Presentation/                   # UI & ViewModels
│   ├── Scenes/
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── DashboardViewModel.swift
│   │   │   └── DashboardUpdateProtocol.swift
│   │   │
│   │   ├── User/
│   │   │   ├── CreateUserView.swift
│   │   │   ├── CreateUserViewModel.swift
│   │   │   ├── CreateFirstUserView.swift
│   │   │   └── CreateFirstUserViewModel.swift
│   │   │
│   │   └── ItemList/
│   │       ├── AddItemListView.swift
│   │       └── AddItemListViewModel.swift
│   │
│   └── Common/                        # Reusable UI components
│       ├── Views/
│       └── Components/
│
├── 🔧 Infrastructure/                 # Cross-cutting concerns
│   ├── Cache/
│   │   └── CacheManager.swift
│   ├── Helpers/
│   │   └── DateFormatterHelper.swift
│   ├── Utils/
│   │   └── DataPreloader.swift
│   └── Extensions/
│       └── Date+Extensions.swift
│
└── 🧪 Tests/
    ├── DomainTests/
    │   ├── UseCases/
    │   │   └── CreateUserUseCaseTests.swift
    │   └── Entities/
    │
    ├── DataTests/
    │   ├── Services/
    │   │   └── UserServiceTests.swift
    │   └── Repositories/
    │       └── UserRepositoryTests.swift
    │
    ├── PresentationTests/
    │   └── ViewModels/
    │       └── CreateUserViewModelTests.swift
    │
    └── TestUtilities/
        ├── TestEntityFactory.swift
        └── TestDataGenerator.swift
```

---

## 6. Protocol Organization

### Before (❌ Scattered)
```
OMOMoney/
├── Protocols/
│   ├── UserRepository.swift
│   └── GroupRepository.swift
│
└── Services/
    ├── Protocols/
    │   ├── UserServiceProtocol.swift
    │   └── GroupServiceProtocol.swift
    │
    ├── UserService.swift
    └── GroupService.swift

Problem: Protocols in 2 different locations!
```

### After (✅ Organized)
```
OMOMoney/
├── Domain/
│   └── Protocols/
│       ├── Repositories/              # All repository protocols
│       │   ├── UserRepository.swift
│       │   └── GroupRepository.swift
│       │
│       └── Services/                  # All service protocols
│           ├── UserServiceProtocol.swift
│           └── GroupServiceProtocol.swift
│
└── Data/
    └── Services/                      # Only implementations
        ├── UserService.swift
        └── GroupService.swift

Solution: Single source of truth for protocols!
```

---

## 7. Dependency Injection Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      App Startup                             │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ AppDIContainer.shared                                       │
│                                                              │
│ ┌────────────────────────────────────────────────────┐     │
│ │ Initialize Core Services                           │     │
│ │ - PersistenceController                            │     │
│ │ - UserService, GroupService, ItemListService       │     │
│ └────────────────────────────────────────────────────┘     │
│                                                              │
│ ┌────────────────────────────────────────────────────┐     │
│ │ Create Repositories                                │     │
│ │ - UserRepository(userService)                      │     │
│ │ - GroupRepository(groupService)                    │     │
│ │ - ItemListRepository(itemListService)              │     │
│ └────────────────────────────────────────────────────┘     │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ UserSceneDIContainer                                        │
│                                                              │
│ ┌────────────────────────────────────────────────────┐     │
│ │ Create Use Cases                                   │     │
│ │ - CreateUserUseCase(userRepository)                │     │
│ │ - FetchUsersUseCase(userRepository)                │     │
│ └────────────────────────────────────────────────────┘     │
│                                                              │
│ ┌────────────────────────────────────────────────────┐     │
│ │ Create ViewModels                                  │     │
│ │ - CreateUserViewModel(createUserUseCase)           │     │
│ └────────────────────────────────────────────────────┘     │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ View Initialization                                         │
│                                                              │
│ CreateUserView(viewModel: sceneDI.makeCreateUserViewModel())│
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Testing Strategy Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      UNIT TESTS                              │
└─────────────────────────────────────────────────────────────┘

Domain Tests (Fast, No dependencies)
┌──────────────────────────────────────┐
│ CreateUserUseCaseTests               │
│                                      │
│ Mock: UserRepository                 │
│   ↓                                  │
│ Test: DefaultCreateUserUseCase       │
│   ↓                                  │
│ Verify: Business logic works         │
└──────────────────────────────────────┘

Data Tests (With Core Data in-memory)
┌──────────────────────────────────────┐
│ UserServiceTests                     │
│                                      │
│ Use: In-memory Core Data context     │
│   ↓                                  │
│ Test: UserService CRUD operations    │
│   ↓                                  │
│ Verify: Data persistence works       │
└──────────────────────────────────────┘

Presentation Tests (Mock use cases)
┌──────────────────────────────────────┐
│ CreateUserViewModelTests             │
│                                      │
│ Mock: CreateUserUseCase              │
│   ↓                                  │
│ Test: CreateUserViewModel            │
│   ↓                                  │
│ Verify: UI state updates correctly   │
└──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  INTEGRATION TESTS                           │
└─────────────────────────────────────────────────────────────┘

End-to-End Flow
┌──────────────────────────────────────┐
│ UserCreationIntegrationTests         │
│                                      │
│ Real: All layers (except Core Data)  │
│   ↓                                  │
│ View → ViewModel → UseCase →         │
│   Repository → Service →             │
│   In-memory Core Data                │
│   ↓                                  │
│ Verify: Complete flow works          │
└──────────────────────────────────────┘
```

---

## 9. Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Error occurs in Data Layer                                  │
│ (e.g., Core Data save fails)                                │
└────────────────────┬────────────────────────────────────────┘
                     │ throw
┌────────────────────▼────────────────────────────────────────┐
│ Service catches and rethrows                                │
│ (UserService)                                               │
└────────────────────┬────────────────────────────────────────┘
                     │ throw
┌────────────────────▼────────────────────────────────────────┐
│ Repository catches and wraps in RepositoryError             │
│ (DefaultUserRepository)                                     │
└────────────────────┬────────────────────────────────────────┘
                     │ throw
┌────────────────────▼────────────────────────────────────────┐
│ Use Case catches and handles                                │
│ - Validates input → ValidationError                         │
│ - Data errors → RepositoryError                             │
│ (DefaultCreateUserUseCase)                                  │
└────────────────────┬────────────────────────────────────────┘
                     │ throw
┌────────────────────▼────────────────────────────────────────┐
│ ViewModel catches and converts to UI message                │
│ - Sets errorMessage: String                                 │
│ - Shows alert/banner                                        │
│ (CreateUserViewModel)                                       │
└────────────────────┬────────────────────────────────────────┘
                     │ @Published update
┌────────────────────▼────────────────────────────────────────┐
│ View displays error to user                                 │
│ - Alert dialog                                              │
│ - Inline error message                                      │
│ (CreateUserView)                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Clean Architecture Benefits

```
┌─────────────────────────────────────────────────────────────┐
│                   BEFORE REORGANIZATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ❌ Protocols in 2+ locations                               │
│  ❌ Mixed responsibilities                                  │
│  ❌ Hard to find files                                      │
│  ❌ Difficult to test                                       │
│  ❌ Tight coupling                                          │
│  ❌ Hard to scale                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘

                         ↓ REORGANIZE ↓

┌─────────────────────────────────────────────────────────────┐
│                    AFTER REORGANIZATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Single source of truth for protocols                    │
│  ✅ Clear separation of concerns                            │
│  ✅ Easy to navigate                                        │
│  ✅ Highly testable                                         │
│  ✅ Loose coupling                                          │
│  ✅ Scalable architecture                                   │
│                                                              │
│  Benefits:                                                  │
│  • Faster development                                       │
│  • Easier maintenance                                       │
│  • Better onboarding                                        │
│  • Flexible to changes                                      │
│  • Team can work in parallel                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

### Where should I put my new file?

| File Type | Location | Example |
|-----------|----------|---------|
| Domain Model | `Domain/Entities/` | `UserDomain.swift` |
| Repository Protocol | `Domain/Protocols/Repositories/` | `UserRepository.swift` |
| Service Protocol | `Domain/Protocols/Services/` | `UserServiceProtocol.swift` |
| Use Case | `Domain/UseCases/<Feature>/` | `CreateUserUseCase.swift` |
| Repository Impl | `Data/Repositories/` | `DefaultUserRepository.swift` |
| Service Impl | `Data/Services/` | `UserService.swift` |
| Core Data Entity | `Data/CoreData/Entities/` | `User+CoreDataClass.swift` |
| SwiftUI View | `Presentation/Scenes/<Feature>/` | `CreateUserView.swift` |
| ViewModel | `Presentation/Scenes/<Feature>/` | `CreateUserViewModel.swift` |
| Helper | `Infrastructure/Helpers/` | `DateFormatterHelper.swift` |
| DI Container | `Application/DI/` | `AppDIContainer.swift` |

---

**Last Updated**: November 27, 2025
