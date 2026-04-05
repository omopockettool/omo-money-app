# OMOMoney Project Reorganization Plan

## Overview
This document outlines the reorganization of the OMOMoney project to follow Clean Architecture principles more strictly and consolidate protocols into a single, well-organized location.

## Current Issues Identified
1. **Protocols scattered**: Protocols exist in multiple locations (`/Protocols` and `/Services/Protocols`)
2. **Mixed responsibilities**: Service protocols are in the Data layer when they should define Domain contracts
3. **Inconsistent structure**: No clear separation between layers

## New Project Structure

```
OMOMoney/
├── Application/
│   ├── OmoMoneyApp.swift
│   └── DI/
│       ├── AppDIContainer.swift
│       ├── UserSceneDIContainer.swift
│       └── GroupSceneDIContainer.swift
│
├── Domain/
│   ├── Entities/
│   │   ├── UserDomain.swift
│   │   ├── GroupDomain.swift
│   │   ├── ItemListDomain.swift
│   │   ├── CategoryDomain.swift
│   │   └── PaymentMethodDomain.swift
│   │
│   ├── Protocols/
│   │   ├── Repositories/
│   │   │   ├── UserRepository.swift
│   │   │   ├── GroupRepository.swift
│   │   │   ├── ItemListRepository.swift
│   │   │   └── UserGroupRepository.swift
│   │   │
│   │   └── Services/
│   │       ├── UserServiceProtocol.swift
│   │       ├── GroupServiceProtocol.swift
│   │       ├── ItemListServiceProtocol.swift
│   │       ├── CategoryServiceProtocol.swift
│   │       ├── PaymentMethodServiceProtocol.swift
│   │       └── UserGroupServiceProtocol.swift
│   │
│   ├── UseCases/
│   │   ├── User/
│   │   │   ├── CreateUserUseCase.swift (protocol + implementation)
│   │   │   ├── FetchUsersUseCase.swift
│   │   │   ├── UpdateUserUseCase.swift
│   │   │   ├── DeleteUserUseCase.swift
│   │   │   └── SearchUsersUseCase.swift
│   │   │
│   │   ├── Group/
│   │   │   ├── CreateGroupUseCase.swift
│   │   │   ├── FetchGroupsUseCase.swift
│   │   │   ├── UpdateGroupUseCase.swift
│   │   │   └── DeleteGroupUseCase.swift
│   │   │
│   │   ├── ItemList/
│   │   │   ├── CreateItemListUseCase.swift
│   │   │   ├── FetchItemListsUseCase.swift
│   │   │   ├── UpdateItemListUseCase.swift
│   │   │   ├── DeleteItemListUseCase.swift
│   │   │   └── BulkInsertItemListsUseCase.swift
│   │   │
│   │   └── UserGroup/
│   │       └── CreateUserGroupUseCase.swift
│   │
│   └── Errors/
│       ├── RepositoryError.swift
│       └── ValidationError.swift
│
├── Data/
│   ├── CoreData/
│   │   ├── PersistenceController.swift
│   │   ├── OMOMoney.xcdatamodeld
│   │   └── Entities/
│   │       ├── User+CoreDataClass.swift
│   │       ├── User+CoreDataProperties.swift
│   │       ├── Group+CoreDataClass.swift
│   │       ├── Group+CoreDataProperties.swift
│   │       ├── ItemList+CoreDataClass.swift
│   │       ├── ItemList+CoreDataProperties.swift
│   │       ├── Category+CoreDataClass.swift
│   │       ├── PaymentMethod+CoreDataClass.swift
│   │       └── UserGroup+CoreDataClass.swift
│   │
│   ├── Repositories/
│   │   ├── DefaultUserRepository.swift
│   │   ├── DefaultGroupRepository.swift
│   │   ├── DefaultItemListRepository.swift
│   │   └── DefaultUserGroupRepository.swift
│   │
│   └── Services/
│       ├── CoreDataService.swift (Base class)
│       ├── UserService.swift
│       ├── GroupService.swift
│       ├── ItemListService.swift
│       ├── CategoryService.swift
│       ├── PaymentMethodService.swift
│       └── UserGroupService.swift
│
├── Presentation/
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
│   │   ├── Group/
│   │   │   └── (Group-related views)
│   │   │
│   │   └── ItemList/
│   │       ├── AddItemListView.swift
│   │       └── AddItemListViewModel.swift
│   │
│   └── Common/
│       ├── Views/
│       └── Components/
│
├── Infrastructure/
│   ├── Cache/
│   │   └── CacheManager.swift
│   │
│   ├── Helpers/
│   │   └── DateFormatterHelper.swift
│   │
│   ├── Utils/
│   │   └── DataPreloader.swift
│   │
│   └── Extensions/
│       └── (Common extensions)
│
└── Tests/
    ├── DomainTests/
    │   └── UseCases/
    │       └── CreateUserUseCaseTests.swift
    │
    ├── DataTests/
    │   ├── Services/
    │   │   └── UserGroupServiceTests.swift
    │   └── Repositories/
    │
    ├── PresentationTests/
    │   └── ViewModels/
    │       └── CreateFirstUserViewModelTests.swift
    │
    └── TestUtilities/
        ├── TestEntityFactory.swift
        ├── TestDataGenerator.swift
        └── CacheManagerTests.swift
```

## Migration Steps

### Phase 1: Create New Directory Structure
1. Create `Domain/Protocols/Repositories/` directory
2. Create `Domain/Protocols/Services/` directory
3. Create `Domain/UseCases/User/` directory
4. Create `Domain/UseCases/Group/` directory
5. Create `Domain/UseCases/ItemList/` directory
6. Create `Domain/UseCases/UserGroup/` directory
7. Create `Domain/Entities/` directory
8. Create `Domain/Errors/` directory
9. Create `Data/CoreData/Entities/` directory
10. Create `Data/Repositories/` directory
11. Create `Data/Services/` directory
12. Create `Presentation/Scenes/Dashboard/` directory
13. Create `Presentation/Scenes/User/` directory
14. Create `Presentation/Scenes/Group/` directory
15. Create `Presentation/Scenes/ItemList/` directory
16. Create `Presentation/Common/` directory
17. Create `Infrastructure/Cache/` directory
18. Create `Infrastructure/Helpers/` directory
19. Create `Infrastructure/Utils/` directory
20. Create `Application/DI/` directory

### Phase 2: Move Protocol Files
**Move to `Domain/Protocols/Repositories/`:**
- `UserRepository.swift` ✅
- `GroupRepository.swift` ✅
- `ItemListRepository.swift` ✅
- `UserGroupRepository.swift` (if exists)

**Move to `Domain/Protocols/Services/`:**
- All `*ServiceProtocol.swift` files from wherever they currently are
- This includes:
  - `UserServiceProtocol.swift`
  - `GroupServiceProtocol.swift`
  - `ItemListServiceProtocol.swift`
  - `CategoryServiceProtocol.swift`
  - `PaymentMethodServiceProtocol.swift`
  - `UserGroupServiceProtocol.swift`

### Phase 3: Move Use Cases
**Move to respective directories in `Domain/UseCases/`:**
- `CreateUserUseCase.swift` → `Domain/UseCases/User/`
- `FetchUsersUseCase.swift` → `Domain/UseCases/User/`
- `UpdateUserUseCase.swift` → `Domain/UseCases/User/`
- `DeleteUserUseCase.swift` → `Domain/UseCases/User/`
- `SearchUsersUseCase.swift` → `Domain/UseCases/User/`
- `CreateGroupUseCase.swift` → `Domain/UseCases/Group/`
- `FetchGroupsUseCase.swift` → `Domain/UseCases/Group/`
- `UpdateGroupUseCase.swift` → `Domain/UseCases/Group/`
- `DeleteGroupUseCase.swift` → `Domain/UseCases/Group/`
- `CreateItemListUseCase.swift` → `Domain/UseCases/ItemList/`
- `FetchItemListsUseCase.swift` → `Domain/UseCases/ItemList/`
- `UpdateItemListUseCase.swift` → `Domain/UseCases/ItemList/`
- `DeleteItemListUseCase.swift` → `Domain/UseCases/ItemList/`
- `BulkInsertItemListsUseCase.swift` → `Domain/UseCases/ItemList/`
- `CreateUserGroupUseCase.swift` → `Domain/UseCases/UserGroup/`

### Phase 4: Move Domain Entities
**Move to `Domain/Entities/`:**
- All `*Domain.swift` files (UserDomain, GroupDomain, ItemListDomain, etc.)

### Phase 5: Move Data Layer Files
**Move to `Data/Repositories/`:**
- `DefaultUserRepository.swift` ✅
- `DefaultGroupRepository.swift` ✅
- `DefaultItemListRepository.swift`
- `DefaultUserGroupRepository.swift`

**Move to `Data/Services/`:**
- `CoreDataService.swift` ✅
- `UserService.swift`
- `GroupService.swift`
- `ItemListService.swift`
- `CategoryService.swift`
- `PaymentMethodService.swift`
- `UserGroupService.swift`

**Move to `Data/CoreData/Entities/`:**
- All Core Data entity files (`User+CoreDataClass.swift`, etc.)

### Phase 6: Move Presentation Layer
**Move to `Presentation/Scenes/Dashboard/`:**
- `DashboardView.swift`
- `DashboardViewModel.swift`
- `DashboardUpdateProtocol.swift`

**Move to `Presentation/Scenes/User/`:**
- `CreateUserView.swift`
- `CreateUserViewModel.swift`
- `CreateFirstUserView.swift`
- `CreateFirstUserViewModel.swift`

**Move to `Presentation/Scenes/ItemList/`:**
- `AddItemListView.swift`
- `AddItemListViewModel.swift`

### Phase 7: Move Infrastructure
**Move to `Infrastructure/Cache/`:**
- `CacheManager.swift` ✅

**Move to `Infrastructure/Helpers/`:**
- `DateFormatterHelper.swift`

**Move to `Infrastructure/Utils/`:**
- `DataPreloader.swift`

### Phase 8: Move Application Layer
**Move to `Application/DI/`:**
- `AppDIContainer.swift` ✅
- `UserSceneDIContainer.swift` ✅
- `GroupSceneDIContainer.swift` ✅

### Phase 9: Organize Tests
**Move test files to appropriate directories under `Tests/`:**
- `CreateUserUseCaseTests.swift` → `Tests/DomainTests/UseCases/`
- `CreateFirstUserViewModelTests.swift` → `Tests/PresentationTests/ViewModels/`
- `UserGroupServiceTests.swift` → `Tests/DataTests/Services/`
- `CacheManagerTests.swift` → `Tests/InfrastructureTests/`
- `TestEntityFactory.swift` → `Tests/TestUtilities/`
- `TestDataGenerator.swift` → `Tests/TestUtilities/`

### Phase 10: Update Xcode Project
1. In Xcode, create folder groups matching the new structure
2. Move files within Xcode to reflect the new organization
3. Ensure all files are properly referenced in the project
4. Update build phases if necessary

### Phase 11: Cleanup
1. Remove old empty directories
2. Delete duplicate protocol files
3. Verify all imports are correct
4. Run all tests to ensure nothing is broken

## Benefits of This Structure

### 1. Clear Separation of Concerns
- **Domain Layer**: Pure business logic, no dependencies on frameworks
- **Data Layer**: Implementation details, Core Data specific code
- **Presentation Layer**: UI code, ViewModels with SwiftUI
- **Infrastructure**: Cross-cutting concerns (cache, helpers, utils)
- **Application**: App-wide configuration and DI setup

### 2. Single Source of Truth for Protocols
- All repository protocols in one place: `Domain/Protocols/Repositories/`
- All service protocols in one place: `Domain/Protocols/Services/`
- Easy to find and maintain

### 3. Scalability
- Easy to add new features by creating new directories in respective layers
- Clear place for everything
- New team members can quickly understand the structure

### 4. Testability
- Tests organized by layer
- Test utilities in dedicated folder
- Clear separation between unit tests and integration tests

### 5. Dependency Flow
```
Presentation → Domain ← Data
                ↑
         Infrastructure
                ↑
          Application
```

- Domain layer is at the center and has no dependencies
- Data and Presentation layers depend on Domain
- Application layer orchestrates everything through DI

## Implementation Priority

### High Priority (Core Structure)
1. ✅ Consolidate all protocols into `Domain/Protocols/`
2. ✅ Organize use cases by feature in `Domain/UseCases/`
3. ✅ Move repositories to `Data/Repositories/`
4. ✅ Move services to `Data/Services/`

### Medium Priority (Organization)
5. Organize presentation layer by scenes
6. Consolidate infrastructure utilities
7. Organize DI containers

### Low Priority (Polish)
8. Organize tests by layer
9. Create common/shared folders for reusable components
10. Add documentation to each layer

## Notes
- This is a living document - update as implementation progresses
- All file moves should be done in Xcode to maintain project references
- Run tests after each phase to catch any issues early
- Consider creating a feature branch for this reorganization

## Date Created
November 27, 2025
