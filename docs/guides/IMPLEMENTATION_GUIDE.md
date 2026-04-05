# Implementation Guide: Project Reorganization

## Prerequisites
- ✅ Commit all current changes to git
- ✅ Create a new branch: `git checkout -b feature/project-reorganization`
- ✅ Backup your project (optional but recommended)

## Important Notes
⚠️ **DO ALL FILE OPERATIONS IN XCODE** - This ensures project references stay intact
⚠️ **Test after each phase** - Run your test suite to catch issues early
⚠️ **One layer at a time** - Don't try to move everything at once

---

## Phase 1: Create Directory Structure in Xcode

### Step 1.1: Create Domain Layer Structure
1. In Xcode Project Navigator, right-click on `OMOMoney` group
2. Select "New Group" and name it `Domain`
3. Inside `Domain`, create these groups:
   - `Entities`
   - `Protocols`
   - `UseCases`
   - `Errors`

4. Inside `Domain/Protocols`, create:
   - `Repositories`
   - `Services`

5. Inside `Domain/UseCases`, create:
   - `User`
   - `Group`
   - `ItemList`
   - `UserGroup`

### Step 1.2: Create Data Layer Structure
1. Create top-level group `Data`
2. Inside `Data`, create:
   - `CoreData`
   - `Repositories`
   - `Services`

3. Inside `Data/CoreData`, create:
   - `Entities`

### Step 1.3: Create Presentation Layer Structure
1. Create top-level group `Presentation`
2. Inside `Presentation`, create:
   - `Scenes`
   - `Common`

3. Inside `Presentation/Scenes`, create:
   - `Dashboard`
   - `User`
   - `Group`
   - `ItemList`

4. Inside `Presentation/Common`, create:
   - `Views`
   - `Components`

### Step 1.4: Create Infrastructure Layer Structure
1. Create top-level group `Infrastructure`
2. Inside `Infrastructure`, create:
   - `Cache`
   - `Helpers`
   - `Utils`
   - `Extensions`

### Step 1.5: Create Application Layer Structure
1. Create top-level group `Application`
2. Inside `Application`, create:
   - `DI`

### Step 1.6: Organize Tests
1. In your test target, create:
   - `DomainTests`
   - `DataTests`
   - `PresentationTests`
   - `InfrastructureTests`
   - `TestUtilities`

---

## Phase 2: Move Protocol Files

### Step 2.1: Move Repository Protocols
**Destination: `Domain/Protocols/Repositories/`**

In Xcode, drag these files to the `Repositories` group:
- [ ] `UserRepository.swift`
- [ ] `GroupRepository.swift`
- [ ] `ItemListRepository.swift`
- [ ] `UserGroupRepository.swift` (if it exists)

✅ **Test**: Build the project (`Cmd+B`)

### Step 2.2: Find and Move Service Protocols
**Destination: `Domain/Protocols/Services/`**

Service protocols might be scattered. Search for files ending with `ServiceProtocol.swift`:
- [ ] `UserServiceProtocol.swift`
- [ ] `GroupServiceProtocol.swift`
- [ ] `ItemListServiceProtocol.swift`
- [ ] `CategoryServiceProtocol.swift`
- [ ] `PaymentMethodServiceProtocol.swift`
- [ ] `UserGroupServiceProtocol.swift`
- [ ] `ItemServiceProtocol.swift`

**If protocols are defined inline with services:**
You'll need to extract them. Example:

**Before (in UserService.swift):**
```swift
protocol UserServiceProtocol {
    // protocol methods
}

class UserService: UserServiceProtocol {
    // implementation
}
```

**After:**
Create `Domain/Protocols/Services/UserServiceProtocol.swift`:
```swift
import Foundation

protocol UserServiceProtocol {
    // protocol methods
}
```

Keep only the implementation in `Data/Services/UserService.swift`:
```swift
import Foundation
import CoreData

class UserService: UserServiceProtocol {
    // implementation
}
```

✅ **Test**: Build the project (`Cmd+B`)

---

## Phase 3: Move Use Case Files

### Step 3.1: Move User Use Cases
**Destination: `Domain/UseCases/User/`**

Drag these files to the `User` group:
- [ ] `CreateUserUseCase.swift`
- [ ] `FetchUsersUseCase.swift`
- [ ] `UpdateUserUseCase.swift`
- [ ] `DeleteUserUseCase.swift`
- [ ] `SearchUsersUseCase.swift`

### Step 3.2: Move Group Use Cases
**Destination: `Domain/UseCases/Group/`**

- [ ] `CreateGroupUseCase.swift`
- [ ] `FetchGroupsUseCase.swift`
- [ ] `UpdateGroupUseCase.swift`
- [ ] `DeleteGroupUseCase.swift`

### Step 3.3: Move ItemList Use Cases
**Destination: `Domain/UseCases/ItemList/`**

- [ ] `CreateItemListUseCase.swift`
- [ ] `FetchItemListsUseCase.swift`
- [ ] `UpdateItemListUseCase.swift`
- [ ] `DeleteItemListUseCase.swift`
- [ ] `BulkInsertItemListsUseCase.swift`

### Step 3.4: Move UserGroup Use Cases
**Destination: `Domain/UseCases/UserGroup/`**

- [ ] `CreateUserGroupUseCase.swift`
- [ ] Any other UserGroup use cases

✅ **Test**: Build and run tests (`Cmd+U`)

---

## Phase 4: Move Domain Entities

### Step 4.1: Move Domain Models
**Destination: `Domain/Entities/`**

Search for files with "Domain" suffix:
- [ ] `UserDomain.swift`
- [ ] `GroupDomain.swift`
- [ ] `ItemListDomain.swift`
- [ ] `CategoryDomain.swift`
- [ ] `PaymentMethodDomain.swift`
- [ ] `UserGroupDomain.swift`
- [ ] Any other domain entities

### Step 4.2: Move Error Types
**Destination: `Domain/Errors/`**

- [ ] `RepositoryError.swift`
- [ ] `ValidationError.swift`
- [ ] Any other domain-specific errors

✅ **Test**: Build the project (`Cmd+B`)

---

## Phase 5: Move Data Layer Files

### Step 5.1: Move Repository Implementations
**Destination: `Data/Repositories/`**

- [ ] `DefaultUserRepository.swift`
- [ ] `DefaultGroupRepository.swift`
- [ ] `DefaultItemListRepository.swift`
- [ ] `DefaultUserGroupRepository.swift`

### Step 5.2: Move Service Implementations
**Destination: `Data/Services/`**

- [ ] `CoreDataService.swift`
- [ ] `UserService.swift`
- [ ] `GroupService.swift`
- [ ] `ItemListService.swift`
- [ ] `CategoryService.swift`
- [ ] `PaymentMethodService.swift`
- [ ] `UserGroupService.swift`
- [ ] `ItemService.swift`

### Step 5.3: Move Core Data Entities
**Destination: `Data/CoreData/Entities/`**

Move all Core Data generated files:
- [ ] `User+CoreDataClass.swift`
- [ ] `User+CoreDataProperties.swift`
- [ ] `Group+CoreDataClass.swift`
- [ ] `Group+CoreDataProperties.swift`
- [ ] `ItemList+CoreDataClass.swift`
- [ ] `ItemList+CoreDataProperties.swift`
- [ ] `Category+CoreDataClass.swift`
- [ ] `Category+CoreDataProperties.swift`
- [ ] `PaymentMethod+CoreDataClass.swift`
- [ ] `PaymentMethod+CoreDataProperties.swift`
- [ ] `UserGroup+CoreDataClass.swift`
- [ ] `UserGroup+CoreDataProperties.swift`
- [ ] `Item+CoreDataClass.swift` (if exists)

### Step 5.4: Move Core Data Stack
**Destination: `Data/CoreData/`**

- [ ] `PersistenceController.swift`
- [ ] `OMOMoney.xcdatamodeld` (keep at Data/CoreData root)

✅ **Test**: Build and run tests (`Cmd+U`)

---

## Phase 6: Move Presentation Layer

### Step 6.1: Move Dashboard Scene
**Destination: `Presentation/Scenes/Dashboard/`**

- [ ] `DashboardView.swift`
- [ ] `DashboardViewModel.swift`
- [ ] `DashboardUpdateProtocol.swift`

### Step 6.2: Move User Scene
**Destination: `Presentation/Scenes/User/`**

- [ ] `CreateUserView.swift`
- [ ] `CreateUserViewModel.swift`
- [ ] `CreateFirstUserView.swift`
- [ ] `CreateFirstUserViewModel.swift`
- [ ] Any other user-related views

### Step 6.3: Move ItemList Scene
**Destination: `Presentation/Scenes/ItemList/`**

- [ ] `AddItemListView.swift`
- [ ] `AddItemListViewModel.swift`
- [ ] Any other item list views

### Step 6.4: Move Group Scene
**Destination: `Presentation/Scenes/Group/`**

- [ ] Any group-related views and view models

### Step 6.5: Move Common UI Components
**Destination: `Presentation/Common/`**

- [ ] Any reusable views
- [ ] Any reusable components
- [ ] Any view extensions

✅ **Test**: Build and run the app (`Cmd+R`)

---

## Phase 7: Move Infrastructure

### Step 7.1: Move Cache Components
**Destination: `Infrastructure/Cache/`**

- [ ] `CacheManager.swift`

### Step 7.2: Move Helpers
**Destination: `Infrastructure/Helpers/`**

- [ ] `DateFormatterHelper.swift`
- [ ] Any other helper classes

### Step 7.3: Move Utilities
**Destination: `Infrastructure/Utils/`**

- [ ] `DataPreloader.swift`
- [ ] Any other utility classes

### Step 7.4: Move Extensions
**Destination: `Infrastructure/Extensions/`**

- [ ] Any Swift extensions
- [ ] Any category files

✅ **Test**: Build the project (`Cmd+B`)

---

## Phase 8: Move Application Layer

### Step 8.1: Move DI Containers
**Destination: `Application/DI/`**

- [ ] `AppDIContainer.swift`
- [ ] `UserSceneDIContainer.swift`
- [ ] `GroupSceneDIContainer.swift`
- [ ] Any other DI containers

### Step 8.2: Keep at Application Root
- [ ] `OmoMoneyApp.swift` (main app file)
- [ ] `AppDelegate.swift` (if exists)

✅ **Test**: Build and run the app (`Cmd+R`)

---

## Phase 9: Organize Tests

### Step 9.1: Move Domain Tests
**Destination: `Tests/DomainTests/`**

Create subdirectories:
- `UseCases/`
- `Entities/`

Move:
- [ ] `CreateUserUseCaseTests.swift` → `UseCases/`
- [ ] Any other use case tests

### Step 9.2: Move Data Tests
**Destination: `Tests/DataTests/`**

Create subdirectories:
- `Services/`
- `Repositories/`

Move:
- [ ] `UserGroupServiceTests.swift` → `Services/`
- [ ] Any repository tests

### Step 9.3: Move Presentation Tests
**Destination: `Tests/PresentationTests/`**

Create subdirectories:
- `ViewModels/`

Move:
- [ ] `CreateFirstUserViewModelTests.swift` → `ViewModels/`
- [ ] Any other view model tests

### Step 9.4: Move Infrastructure Tests
**Destination: `Tests/InfrastructureTests/`**

- [ ] `CacheManagerTests.swift`

### Step 9.5: Move Test Utilities
**Destination: `Tests/TestUtilities/`**

- [ ] `TestEntityFactory.swift`
- [ ] `TestDataGenerator.swift`
- [ ] Any other test helpers

✅ **Test**: Run all tests (`Cmd+U`)

---

## Phase 10: Final Cleanup

### Step 10.1: Remove Old Directories
In Xcode, delete these groups if they're now empty:
- [ ] Old `Protocols` folder (if separate)
- [ ] Old `Services/Protocols` folder
- [ ] Any other empty folders

### Step 10.2: Verify Build Settings
1. Check target membership for all files
2. Ensure all files are in correct targets (main app vs tests)
3. Check that no files are red (missing references)

### Step 10.3: Update Documentation
- [ ] Create `Domain/README.md` explaining domain layer
- [ ] Create `Data/README.md` explaining data layer
- [ ] Create `Presentation/README.md` explaining presentation layer
- [ ] Update main project README if it exists

### Step 10.4: Final Tests
- [ ] Clean build folder (`Cmd+Shift+K`)
- [ ] Build project (`Cmd+B`)
- [ ] Run all tests (`Cmd+U`)
- [ ] Run the app (`Cmd+R`)
- [ ] Test main user flows

---

## Phase 11: Commit and Review

### Step 11.1: Review Changes
```bash
# Check what changed
git status

# Review the diff
git diff
```

### Step 11.2: Commit
```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Reorganize project structure following Clean Architecture

- Consolidate all protocols in Domain/Protocols/
- Organize use cases by feature in Domain/UseCases/
- Separate Data layer (Services, Repositories, Core Data)
- Organize Presentation layer by scenes
- Create Infrastructure layer for cross-cutting concerns
- Organize Application layer with DI containers
- Reorganize tests by layer

This improves code organization, maintainability, and follows
Clean Architecture principles more strictly."
```

### Step 11.3: Verify
```bash
# Ensure everything still works
# Build and test from command line
xcodebuild -scheme OMOMoney -destination 'platform=iOS Simulator,name=iPhone 15' clean build test
```

---

## Troubleshooting

### Issue: "Cannot find 'X' in scope"
**Solution**: Check import statements. You might need to add imports after moving files.

### Issue: "Circular dependency"
**Solution**: Review your dependencies. Domain should not import Data or Presentation.

### Issue: Red files in Xcode
**Solution**: 
1. Remove the file reference (delete, choose "Remove Reference")
2. Re-add the file from its new location

### Issue: Tests failing
**Solution**: 
1. Check if test target membership is correct
2. Verify all test utilities are accessible
3. Update any hardcoded references to old locations

### Issue: Build errors in CI/CD
**Solution**: 
1. Ensure all files are committed
2. Check .gitignore isn't excluding important files
3. Verify project.pbxproj is committed correctly

---

## Post-Implementation Checklist

- [ ] All files successfully moved
- [ ] Project builds without errors
- [ ] All tests pass
- [ ] App runs correctly
- [ ] No compiler warnings
- [ ] Documentation updated
- [ ] Changes committed to git
- [ ] Team members notified of new structure
- [ ] README updated with new structure
- [ ] Consider creating architecture decision record (ADR)

---

## Benefits You'll See

✅ **Easier Navigation**: Find files faster with logical grouping
✅ **Better Testability**: Clear separation makes testing easier
✅ **Reduced Confusion**: Single source of truth for protocols
✅ **Scalability**: Easy to add new features
✅ **Onboarding**: New developers understand structure quickly
✅ **Maintainability**: Changes are isolated to specific layers

---

## Estimated Time

- **Phase 1** (Directory creation): 15 minutes
- **Phase 2** (Protocols): 30 minutes
- **Phase 3** (Use cases): 20 minutes
- **Phase 4** (Domain entities): 15 minutes
- **Phase 5** (Data layer): 45 minutes
- **Phase 6** (Presentation layer): 30 minutes
- **Phase 7** (Infrastructure): 15 minutes
- **Phase 8** (Application layer): 10 minutes
- **Phase 9** (Tests): 30 minutes
- **Phase 10** (Cleanup): 20 minutes
- **Phase 11** (Commit): 10 minutes

**Total**: Approximately 4 hours

---

## Questions or Issues?

If you encounter any issues during the reorganization:
1. Don't panic - everything is in git
2. Take a screenshot of the error
3. Check the Troubleshooting section above
4. You can always revert: `git checkout .`

Good luck! 🚀
