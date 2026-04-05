# Project Reorganization Checklist

Use this checklist to track your progress during the reorganization.

## Pre-Flight Check
- [ ] All changes committed to git
- [ ] Created branch: `feature/project-reorganization`
- [ ] Read `PROJECT_REORGANIZATION_PLAN.md`
- [ ] Read `IMPLEMENTATION_GUIDE.md`
- [ ] Backed up project (optional)

---

## Phase 1: Directory Structure ⏱️ 15 min

### Domain Layer
- [ ] Created `Domain/` group
- [ ] Created `Domain/Entities/`
- [ ] Created `Domain/Protocols/`
- [ ] Created `Domain/Protocols/Repositories/`
- [ ] Created `Domain/Protocols/Services/`
- [ ] Created `Domain/UseCases/`
- [ ] Created `Domain/UseCases/User/`
- [ ] Created `Domain/UseCases/Group/`
- [ ] Created `Domain/UseCases/ItemList/`
- [ ] Created `Domain/UseCases/UserGroup/`
- [ ] Created `Domain/Errors/`

### Data Layer
- [ ] Created `Data/` group
- [ ] Created `Data/CoreData/`
- [ ] Created `Data/CoreData/Entities/`
- [ ] Created `Data/Repositories/`
- [ ] Created `Data/Services/`

### Presentation Layer
- [ ] Created `Presentation/` group
- [ ] Created `Presentation/Scenes/`
- [ ] Created `Presentation/Scenes/Dashboard/`
- [ ] Created `Presentation/Scenes/User/`
- [ ] Created `Presentation/Scenes/Group/`
- [ ] Created `Presentation/Scenes/ItemList/`
- [ ] Created `Presentation/Common/`
- [ ] Created `Presentation/Common/Views/`
- [ ] Created `Presentation/Common/Components/`

### Infrastructure Layer
- [ ] Created `Infrastructure/` group
- [ ] Created `Infrastructure/Cache/`
- [ ] Created `Infrastructure/Helpers/`
- [ ] Created `Infrastructure/Utils/`
- [ ] Created `Infrastructure/Extensions/`

### Application Layer
- [ ] Created `Application/` group
- [ ] Created `Application/DI/`

### Test Organization
- [ ] Created `Tests/DomainTests/`
- [ ] Created `Tests/DomainTests/UseCases/`
- [ ] Created `Tests/DomainTests/Entities/`
- [ ] Created `Tests/DataTests/`
- [ ] Created `Tests/DataTests/Services/`
- [ ] Created `Tests/DataTests/Repositories/`
- [ ] Created `Tests/PresentationTests/`
- [ ] Created `Tests/PresentationTests/ViewModels/`
- [ ] Created `Tests/InfrastructureTests/`
- [ ] Created `Tests/TestUtilities/`

**✅ Checkpoint**: Build project (`Cmd+B`)

---

## Phase 2: Move Protocols ⏱️ 30 min

### Repository Protocols → `Domain/Protocols/Repositories/`
- [ ] `UserRepository.swift`
- [ ] `GroupRepository.swift`
- [ ] `ItemListRepository.swift`
- [ ] `UserGroupRepository.swift`
- [ ] `CategoryRepository.swift` (if exists)
- [ ] `PaymentMethodRepository.swift` (if exists)

### Service Protocols → `Domain/Protocols/Services/`
- [ ] `UserServiceProtocol.swift`
- [ ] `GroupServiceProtocol.swift`
- [ ] `ItemListServiceProtocol.swift`
- [ ] `CategoryServiceProtocol.swift`
- [ ] `PaymentMethodServiceProtocol.swift`
- [ ] `UserGroupServiceProtocol.swift`
- [ ] `ItemServiceProtocol.swift`

**Note**: If protocols are inline with implementations, extract them first!

**✅ Checkpoint**: Build project (`Cmd+B`)

---

## Phase 3: Move Use Cases ⏱️ 20 min

### User Use Cases → `Domain/UseCases/User/`
- [ ] `CreateUserUseCase.swift`
- [ ] `FetchUsersUseCase.swift`
- [ ] `UpdateUserUseCase.swift`
- [ ] `DeleteUserUseCase.swift`
- [ ] `SearchUsersUseCase.swift`

### Group Use Cases → `Domain/UseCases/Group/`
- [ ] `CreateGroupUseCase.swift`
- [ ] `FetchGroupsUseCase.swift`
- [ ] `UpdateGroupUseCase.swift`
- [ ] `DeleteGroupUseCase.swift`

### ItemList Use Cases → `Domain/UseCases/ItemList/`
- [ ] `CreateItemListUseCase.swift`
- [ ] `FetchItemListsUseCase.swift`
- [ ] `UpdateItemListUseCase.swift`
- [ ] `DeleteItemListUseCase.swift`
- [ ] `BulkInsertItemListsUseCase.swift`

### UserGroup Use Cases → `Domain/UseCases/UserGroup/`
- [ ] `CreateUserGroupUseCase.swift`
- [ ] Other UserGroup use cases

**✅ Checkpoint**: Build and run tests (`Cmd+U`)

---

## Phase 4: Move Domain Entities ⏱️ 15 min

### Domain Models → `Domain/Entities/`
- [ ] `UserDomain.swift`
- [ ] `GroupDomain.swift`
- [ ] `ItemListDomain.swift`
- [ ] `CategoryDomain.swift`
- [ ] `PaymentMethodDomain.swift`
- [ ] `UserGroupDomain.swift`
- [ ] `ItemDomain.swift` (if exists)

### Error Types → `Domain/Errors/`
- [ ] `RepositoryError.swift`
- [ ] `ValidationError.swift`
- [ ] Other domain errors

**✅ Checkpoint**: Build project (`Cmd+B`)

---

## Phase 5: Move Data Layer ⏱️ 45 min

### Repositories → `Data/Repositories/`
- [ ] `DefaultUserRepository.swift`
- [ ] `DefaultGroupRepository.swift`
- [ ] `DefaultItemListRepository.swift`
- [ ] `DefaultUserGroupRepository.swift`
- [ ] `DefaultCategoryRepository.swift` (if exists)
- [ ] `DefaultPaymentMethodRepository.swift` (if exists)

### Services → `Data/Services/`
- [ ] `CoreDataService.swift`
- [ ] `UserService.swift`
- [ ] `GroupService.swift`
- [ ] `ItemListService.swift`
- [ ] `CategoryService.swift`
- [ ] `PaymentMethodService.swift`
- [ ] `UserGroupService.swift`
- [ ] `ItemService.swift`

### Core Data Entities → `Data/CoreData/Entities/`
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
- [ ] `Item+CoreDataProperties.swift` (if exists)

### Core Data Stack → `Data/CoreData/`
- [ ] `PersistenceController.swift`
- [ ] `OMOMoney.xcdatamodeld`

**✅ Checkpoint**: Build and run tests (`Cmd+U`)

---

## Phase 6: Move Presentation Layer ⏱️ 30 min

### Dashboard Scene → `Presentation/Scenes/Dashboard/`
- [ ] `DashboardView.swift`
- [ ] `DashboardViewModel.swift`
- [ ] `DashboardUpdateProtocol.swift`

### User Scene → `Presentation/Scenes/User/`
- [ ] `CreateUserView.swift`
- [ ] `CreateUserViewModel.swift`
- [ ] `CreateFirstUserView.swift`
- [ ] `CreateFirstUserViewModel.swift`
- [ ] `UserListView.swift` (if exists)
- [ ] Other user views

### Group Scene → `Presentation/Scenes/Group/`
- [ ] `CreateGroupView.swift` (if exists)
- [ ] `CreateGroupViewModel.swift` (if exists)
- [ ] `GroupListView.swift` (if exists)
- [ ] Other group views

### ItemList Scene → `Presentation/Scenes/ItemList/`
- [ ] `AddItemListView.swift`
- [ ] `AddItemListViewModel.swift`
- [ ] `ItemListDetailView.swift` (if exists)
- [ ] Other item list views

### Common UI → `Presentation/Common/`
- [ ] Common views
- [ ] Reusable components
- [ ] UI helpers

**✅ Checkpoint**: Build and run app (`Cmd+R`)

---

## Phase 7: Move Infrastructure ⏱️ 15 min

### Cache → `Infrastructure/Cache/`
- [ ] `CacheManager.swift`

### Helpers → `Infrastructure/Helpers/`
- [ ] `DateFormatterHelper.swift`
- [ ] Other helper classes

### Utils → `Infrastructure/Utils/`
- [ ] `DataPreloader.swift`
- [ ] Other utility classes

### Extensions → `Infrastructure/Extensions/`
- [ ] Swift extensions
- [ ] Category files

**✅ Checkpoint**: Build project (`Cmd+B`)

---

## Phase 8: Move Application Layer ⏱️ 10 min

### DI Containers → `Application/DI/`
- [ ] `AppDIContainer.swift`
- [ ] `UserSceneDIContainer.swift`
- [ ] `GroupSceneDIContainer.swift`
- [ ] Other DI containers

### Keep at Application Root
- [ ] `OmoMoneyApp.swift`
- [ ] `AppDelegate.swift` (if exists)

**✅ Checkpoint**: Build and run app (`Cmd+R`)

---

## Phase 9: Move Tests ⏱️ 30 min

### Domain Tests → `Tests/DomainTests/`
- [ ] `CreateUserUseCaseTests.swift` → `UseCases/`
- [ ] Other use case tests → `UseCases/`
- [ ] Entity tests → `Entities/`

### Data Tests → `Tests/DataTests/`
- [ ] `UserGroupServiceTests.swift` → `Services/`
- [ ] Other service tests → `Services/`
- [ ] Repository tests → `Repositories/`

### Presentation Tests → `Tests/PresentationTests/`
- [ ] `CreateFirstUserViewModelTests.swift` → `ViewModels/`
- [ ] Other view model tests → `ViewModels/`

### Infrastructure Tests → `Tests/InfrastructureTests/`
- [ ] `CacheManagerTests.swift`
- [ ] Other infrastructure tests

### Test Utilities → `Tests/TestUtilities/`
- [ ] `TestEntityFactory.swift`
- [ ] `TestDataGenerator.swift`
- [ ] Other test helpers

**✅ Checkpoint**: Run all tests (`Cmd+U`)

---

## Phase 10: Cleanup ⏱️ 20 min

### Remove Old Directories
- [ ] Deleted old `Protocols/` folder (if empty)
- [ ] Deleted old `Services/Protocols/` folder (if empty)
- [ ] Deleted any other empty folders
- [ ] Removed duplicate files

### Verify Structure
- [ ] All files properly organized
- [ ] No red (missing) files in Xcode
- [ ] All files have correct target membership
- [ ] Project navigator is clean and organized

### Documentation
- [ ] Created `Domain/README.md`
- [ ] Created `Data/README.md`
- [ ] Created `Presentation/README.md`
- [ ] Updated main project README (if exists)

### Final Testing
- [ ] Clean build folder (`Cmd+Shift+K`)
- [ ] Build project (`Cmd+B`) - No errors
- [ ] Run all tests (`Cmd+U`) - All passing
- [ ] Run the app (`Cmd+R`) - Works correctly
- [ ] Test main user flows - All working

**✅ Final Checkpoint**: Everything builds and runs!

---

## Phase 11: Git Commit ⏱️ 10 min

### Review Changes
- [ ] `git status` - Checked what changed
- [ ] `git diff` - Reviewed the diff
- [ ] No unintended changes
- [ ] All files properly moved

### Commit
- [ ] `git add .` - Staged all changes
- [ ] `git commit -m "Reorganize project structure..."` - Committed with descriptive message
- [ ] `git log --oneline` - Verified commit

### Verify
- [ ] Built from clean state
- [ ] All tests pass
- [ ] App runs correctly

**✅ Complete!** 🎉

---

## Post-Implementation

### Optional Next Steps
- [ ] Create PR for team review
- [ ] Update CI/CD configuration (if needed)
- [ ] Update documentation
- [ ] Share new structure with team
- [ ] Create architecture decision record (ADR)
- [ ] Update onboarding docs for new developers

### Celebrate! 🎊
- [ ] Project is now properly organized
- [ ] Clean Architecture implemented correctly
- [ ] Single source of truth for protocols
- [ ] Easy to navigate and maintain
- [ ] Ready for future growth

---

## Troubleshooting

### If Something Breaks:

1. **Don't Panic** 🧘
   - Everything is in git
   - You can revert: `git checkout .`

2. **Check Build Errors**
   - Read error messages carefully
   - Usually just missing imports
   - Or incorrect target membership

3. **Verify File Locations**
   - Files moved correctly in Xcode?
   - All references updated?
   - No duplicate files?

4. **Test Incrementally**
   - Don't move everything at once
   - Test after each phase
   - Easier to identify issues

5. **Ask for Help**
   - Check `IMPLEMENTATION_GUIDE.md`
   - Look at `CLEAN_ARCHITECTURE_GUIDE.md`
   - Consult with team

---

## Time Tracking

| Phase | Estimated | Actual | Notes |
|-------|-----------|--------|-------|
| Phase 1: Directory Structure | 15 min | ___ min | |
| Phase 2: Protocols | 30 min | ___ min | |
| Phase 3: Use Cases | 20 min | ___ min | |
| Phase 4: Entities | 15 min | ___ min | |
| Phase 5: Data Layer | 45 min | ___ min | |
| Phase 6: Presentation | 30 min | ___ min | |
| Phase 7: Infrastructure | 15 min | ___ min | |
| Phase 8: Application | 10 min | ___ min | |
| Phase 9: Tests | 30 min | ___ min | |
| Phase 10: Cleanup | 20 min | ___ min | |
| Phase 11: Commit | 10 min | ___ min | |
| **Total** | **~4 hours** | **___ hours** | |

---

## Progress Summary

**Start Time**: _______________
**End Time**: _______________
**Total Duration**: _______________

**Phases Completed**: ___ / 11

**Status**: 
- [ ] Not Started
- [ ] In Progress
- [ ] Completed
- [ ] Verified

**Notes**:
_________________________________________________________
_________________________________________________________
_________________________________________________________

---

**Date**: November 27, 2025
**By**: _________________
