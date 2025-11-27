# 🔄 ViewModel Migration Guide - Old Pattern to Clean Architecture

## Overview

This guide shows how we migrated User ViewModels from the old pattern (direct Service calls) to Clean Architecture (Use Cases).

---

## ✅ What Was Changed

### ViewModels Migrated
- ✅ `CreateFirstUserViewModel` - First user creation (app onboarding)
- ✅ `CreateUserViewModel` - Regular user creation

### Key Changes
1. **Removed**: Direct dependency on Services and Core Data Context
2. **Added**: Use Cases for business logic
3. **Added**: DI Container integration
4. **Added**: Localized error messages
5. **Improved**: Validation and error handling

---

## 📊 Before & After Comparison

### ❌ Old Pattern (Direct Services)

```swift
@MainActor
class CreateFirstUserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    
    private let context: NSManagedObjectContext
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.userService = UserService(context: context)
        self.groupService = GroupService(context: context)
    }
    
    func createUser() async {
        do {
            // Direct service calls
            let user = try await userService.createUser(name: name, email: email)
            let group = try await groupService.createGroup(name: "Personal", currency: "USD")
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}
```

**Problems:**
- ❌ Tight coupling to Core Data
- ❌ Business logic in ViewModel
- ❌ Hard to test (requires Core Data stack)
- ❌ No validation in domain layer
- ❌ Hard-coded error messages

---

### ✅ New Pattern (Clean Architecture with Use Cases)

```swift
@MainActor
class CreateFirstUserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    
    private let createUserUseCase: CreateUserUseCase
    private let createGroupUseCase: CreateGroupUseCase
    
    init(
        createUserUseCase: CreateUserUseCase,
        createGroupUseCase: CreateGroupUseCase
    ) {
        self.createUserUseCase = createUserUseCase
        self.createGroupUseCase = createGroupUseCase
    }
    
    convenience init() {
        let appContainer = AppDIContainer.shared
        let userSceneContainer = appContainer.makeUserSceneDIContainer()
        let groupSceneContainer = appContainer.makeGroupSceneDIContainer()
        
        self.init(
            createUserUseCase: userSceneContainer.makeCreateUserUseCase(),
            createGroupUseCase: groupSceneContainer.makeCreateGroupUseCase()
        )
    }
    
    func createUser() async {
        do {
            // Use Cases handle validation and business logic
            let userDomain = try await createUserUseCase.execute(name: name, email: email)
            let groupDomain = try await createGroupUseCase.execute(name: "Personal", currency: "USD")
            
        } catch let error as ValidationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = LocalizationKey.RepositoryError.saveFailed.localized
        }
    }
}
```

**Benefits:**
- ✅ No Core Data dependencies
- ✅ Business logic in Use Cases
- ✅ Easy to test with mock repositories
- ✅ Validation in domain layer
- ✅ Localized error messages
- ✅ Clear separation of concerns

---

## 🔑 Key Improvements

### 1. Dependency Injection

**Old:**
```swift
init(context: NSManagedObjectContext) {
    self.context = context
    self.userService = UserService(context: context)
}
```

**New:**
```swift
init(
    createUserUseCase: CreateUserUseCase,
    createGroupUseCase: CreateGroupUseCase
) {
    self.createUserUseCase = createUserUseCase
    self.createGroupUseCase = createGroupUseCase
}

// Convenience initializer for Views
convenience init() {
    let container = AppDIContainer.shared
    // Get use cases from DI container
}
```

### 2. Business Logic Location

**Old:** Mixed in ViewModel
```swift
func createUser() async {
    // Validation here
    guard !name.isEmpty else { return }
    
    // Trimming here
    let trimmedName = name.trimmingCharacters(in: .whitespace)
    
    // Service call
    let user = try await userService.createUser(name: trimmedName, email: email)
}
```

**New:** Encapsulated in Use Cases
```swift
func createUser() async {
    // ViewModel only handles UI concerns
    // Use Case handles validation, trimming, and business rules
    let userDomain = try await createUserUseCase.execute(name: name, email: email)
}
```

### 3. Error Handling

**Old:** Generic error messages
```swift
catch {
    errorMessage = "Error creating user: \(error.localizedDescription)"
}
```

**New:** Specific, localized error messages
```swift
catch let error as ValidationError {
    errorMessage = error.localizedDescription // Localized
} catch {
    errorMessage = LocalizationKey.RepositoryError.saveFailed.localized
}
```

### 4. Testability

**Old:** Requires Core Data setup
```swift
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
let viewModel = CreateFirstUserViewModel(context: context)
// Hard to test, slow tests
```

**New:** Use mock repositories
```swift
let mockUserRepo = MockUserRepository()
let mockGroupRepo = MockGroupRepository()
let createUserUseCase = DefaultCreateUserUseCase(userRepository: mockUserRepo)
let createGroupUseCase = DefaultCreateGroupUseCase(groupRepository: mockGroupRepo)
let viewModel = CreateFirstUserViewModel(
    createUserUseCase: createUserUseCase,
    createGroupUseCase: createGroupUseCase
)
// Fast, isolated tests
```

---

## 🧪 Testing Example

### Old Pattern Test (Complex)
```swift
func testCreateUser() async {
    // Setup Core Data stack
    let container = NSPersistentContainer(name: "OMOMoney")
    // Load persistent stores
    // Setup context
    // Create ViewModel
    // Test...
    // Cleanup Core Data
}
```

### New Pattern Test (Simple)
```swift
func testCreateUser() async {
    // Setup mocks
    let mockUserRepo = MockUserRepository()
    let mockGroupRepo = MockGroupRepository()
    
    // Setup use cases
    let createUserUseCase = DefaultCreateUserUseCase(userRepository: mockUserRepo)
    let createGroupUseCase = DefaultCreateGroupUseCase(groupRepository: mockGroupRepo)
    
    // Setup ViewModel
    let viewModel = CreateFirstUserViewModel(
        createUserUseCase: createUserUseCase,
        createGroupUseCase: createGroupUseCase
    )
    
    // Test
    viewModel.name = "John"
    viewModel.email = "john@test.com"
    await viewModel.createUser()
    
    // Verify
    XCTAssertTrue(mockUserRepo.createUserCalled)
    XCTAssertTrue(viewModel.isSuccess)
}
```

---

## 📝 Migration Checklist

When migrating a ViewModel to Clean Architecture:

### 1. Identify Dependencies
- [ ] What Services does it use?
- [ ] What business operations does it perform?

### 2. Create/Use Use Cases
- [ ] Create Use Case protocols if needed
- [ ] Implement Use Cases
- [ ] Add validation to Use Cases

### 3. Update ViewModel
- [ ] Remove Service dependencies
- [ ] Add Use Case dependencies
- [ ] Update init to accept Use Cases
- [ ] Add convenience init with DI Container
- [ ] Update methods to use Use Cases
- [ ] Add proper error handling

### 4. Update Error Messages
- [ ] Replace hard-coded strings with LocalizationKey
- [ ] Handle ValidationError specifically
- [ ] Use localized error messages

### 5. Write Tests
- [ ] Create mock repositories if needed
- [ ] Write ViewModel tests with mocks
- [ ] Test success cases
- [ ] Test validation errors
- [ ] Test edge cases

### 6. Update Views
- [ ] Update View to use convenience init
- [ ] Or inject Use Cases from parent

---

## 🎯 Benefits Achieved

### For CreateFirstUserViewModel

**Before:**
- 80 lines of code
- Tight Core Data coupling
- Hard to test
- Mixed concerns

**After:**
- 70 lines of code (cleaner)
- No Core Data dependencies
- Easy to test
- Clear separation of concerns
- Localized errors
- Better validation

### Test Coverage

**Old Pattern:**
- ❌ No ViewModel tests (too complex)

**New Pattern:**
- ✅ 13 unit tests for CreateFirstUserViewModel
- ✅ Fast execution (no Core Data)
- ✅ Isolated tests
- ✅ High coverage

---

## 🚀 Next Steps

### Remaining ViewModels to Migrate

1. **UserListViewModel** - List and fetch users
2. **EditUserViewModel** - Update existing user
3. **UserDetailViewModel** - Show user details
4. **GroupListViewModel** - List and fetch groups
5. **All other ViewModels** - Apply same pattern

### Migration Priority

**High Priority:**
1. ✅ CreateFirstUserViewModel (Done)
2. ✅ CreateUserViewModel (Done)
3. UserListViewModel
4. GroupListViewModel

**Medium Priority:**
5. EditUserViewModel
6. CategoryListViewModel
7. PaymentMethodListViewModel

**Low Priority:**
8. Detail ViewModels
9. Dashboard ViewModels

---

## 📚 Additional Resources

- **CLEAN_ARCHITECTURE_IMPLEMENTATION.md** - Full architecture guide
- **Use Case Tests** - Examples in `OMOMoneyTests/Domain/UseCases/`
- **ViewModel Tests** - Examples in `OMOMoneyTests/ViewModel/`
- **DI Container** - `Application/DIContainer/AppDIContainer.swift`

---

**Migration Started:** November 18, 2025  
**Status:** ✅ First ViewModels Migrated (CreateFirstUser & CreateUser)  
**Next:** UserListViewModel migration
