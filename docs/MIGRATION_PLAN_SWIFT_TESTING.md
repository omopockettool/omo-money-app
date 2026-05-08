# 🧪 Swift Testing Migration Plan

**Priority:** MEDIUM  
**Status:** Planning Phase  
**Estimated Effort:** 1-2 weeks  
**Target:** Swift 6.0+ (Available now in Xcode 16+)

---

## 📋 Executive Summary

Swift Testing is Apple's modern, macro-based testing framework that provides a superior alternative to XCTest. If OMOMoney currently uses XCTest (or has no tests), migrating to Swift Testing offers significant benefits.

### Why Migrate to Swift Testing?

✅ **Modern Swift Syntax** - Uses macros like `@Test`, `@Suite`  
✅ **Better Discoverability** - Tests are functions, not methods  
✅ **Improved Assertions** - `#expect()` vs `XCTAssertEqual()`  
✅ **Parameterized Testing** - Test multiple inputs easily  
✅ **Better Error Messages** - More context on failures  
✅ **Async/Await Native** - No need for expectations  
✅ **Parallel Execution** - Faster test suites by default

---

## 🎯 Current State Assessment

### Likely Current Testing Setup (if exists)

```swift
// Typical XCTest approach
import XCTest
@testable import OMOMoney

class UserServiceTests: XCTestCase {
    var sut: UserService!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        context = PersistenceController.preview.container.viewContext
        sut = UserService(context: context)
    }
    
    override func tearDown() {
        sut = nil
        context = nil
        super.tearDown()
    }
    
    func testCreateUser() {
        // Given
        let name = "Test User"
        let email = "test@example.com"
        
        // When
        let expectation = self.expectation(description: "User created")
        Task {
            let user = try await sut.createUser(name: name, email: email)
            
            // Then
            XCTAssertNotNil(user)
            XCTAssertEqual(user.name, name)
            XCTAssertEqual(user.email, email)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
```

---

## 🚀 Migration Strategy

### Phase 1: Setup Swift Testing Framework (Day 1)

#### 1.1 Add Swift Testing to Project

Swift Testing is built into Xcode 16+, no additional setup needed!

#### 1.2 Create Test File Structure

```
OMOMoneyTests/
├── DomainTests/
│   ├── UserTests.swift
│   ├── GroupTests.swift
│   ├── CategoryTests.swift
│   └── ItemListTests.swift
├── UseCaseTests/
│   ├── CreateUserUseCaseTests.swift
│   ├── FetchItemListsUseCaseTests.swift
│   └── DeleteItemListUseCaseTests.swift
├── ViewModelTests/
│   ├── DashboardViewModelTests.swift
│   └── UserListViewModelTests.swift
└── IntegrationTests/
    ├── EndToEndFlowTests.swift
    └── DataMigrationTests.swift
```

---

### Phase 2: Convert Existing Tests (Days 2-5)

#### 2.1 Basic Test Conversion

```swift
// BEFORE: XCTest
import XCTest
@testable import OMOMoney

class UserServiceTests: XCTestCase {
    func testCreateUser() {
        // ...
    }
}

// AFTER: Swift Testing
import Testing
@testable import OMOMoney

@Suite("User Service Tests")
struct UserServiceTests {
    
    @Test("Create user with valid data")
    func createUserWithValidData() async throws {
        // Given
        let name = "Test User"
        let email = "test@example.com"
        let useCase = AppDIContainer.shared.makeCreateUserUseCase()
        
        // When
        let user = try await useCase.execute(name: name, email: email)
        
        // Then
        #expect(user.name == name)
        #expect(user.email == email)
        #expect(user.id != UUID()) // Has valid UUID
    }
}
```

#### 2.2 Parameterized Testing

```swift
// Test multiple scenarios with one test
@Test(
    "Create user with various email formats",
    arguments: [
        "test@example.com",
        "user.name+tag@example.co.uk",
        "user@subdomain.example.com",
        "test_user@example-domain.com"
    ]
)
func createUserWithDifferentEmails(email: String) async throws {
    let useCase = AppDIContainer.shared.makeCreateUserUseCase()
    let user = try await useCase.execute(name: "Test", email: email)
    
    #expect(user.email == email)
}
```

#### 2.3 Suite Organization with Tags

```swift
@Suite("Dashboard ViewModel Tests", .tags(.viewModel, .integration))
struct DashboardViewModelTests {
    
    @Test("Load dashboard data for empty group", .tags(.empty))
    func loadDashboardDataEmpty() async throws {
        // ...
    }
    
    @Test("Load dashboard data with items", .tags(.dataPresent))
    func loadDashboardDataWithItems() async throws {
        // ...
    }
    
    @Test("Calculate total spent correctly", .tags(.calculation))
    func calculateTotalSpent() async throws {
        // ...
    }
}

// Run specific tags: swift test --filter .viewModel
// Run excluding tags: swift test --skip .integration
```

---

### Phase 3: Add New Test Types (Days 6-8)

#### 3.1 Async Testing (Native Support)

```swift
@Test("Fetch item lists returns sorted by date")
func fetchItemListsSorted() async throws {
    // Given
    let container = AppDIContainer.shared
    let createItemListUseCase = container.makeCreateItemListUseCase()
    let fetchItemListsUseCase = container.makeFetchItemListsUseCase()
    
    let group = try await createTestGroup()
    let category = try await createTestCategory(in: group)
    let paymentMethod = try await createTestPaymentMethod(in: group)
    
    // When
    let today = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    
    // Create in random order
    let _ = try await createItemListUseCase.execute(
        description: "Today",
        date: today,
        categoryId: category.id,
        paymentMethodId: paymentMethod.id,
        groupId: group.id
    )
    
    let _ = try await createItemListUseCase.execute(
        description: "Yesterday",
        date: yesterday,
        categoryId: category.id,
        paymentMethodId: paymentMethod.id,
        groupId: group.id
    )
    
    // Then - should be sorted by date (newest first)
    let itemLists = try await fetchItemListsUseCase.execute(forGroupId: group.id)
    
    #expect(itemLists.count == 2)
    #expect(itemLists[0].itemListDescription == "Today")
    #expect(itemLists[1].itemListDescription == "Yesterday")
    #expect(itemLists[0].date > itemLists[1].date)
}
```

#### 3.2 Error Testing

```swift
@Test("Create user fails with empty name")
func createUserEmptyName() async throws {
    let useCase = AppDIContainer.shared.makeCreateUserUseCase()
    
    // Expect this to throw an error
    await #expect(throws: ValidationError.self) {
        try await useCase.execute(name: "", email: "test@example.com")
    }
}

@Test("Fetch non-existent item list returns nil")
func fetchNonExistentItemList() async throws {
    let useCase = AppDIContainer.shared.makeFetchItemListsUseCase()
    let randomGroupId = UUID()
    
    let itemLists = try await useCase.execute(forGroupId: randomGroupId)
    
    #expect(itemLists.isEmpty)
}
```

#### 3.3 Conditional Testing

```swift
@Test("iCloud sync", .enabled(if: ProcessInfo.processInfo.environment["ICLOUD_ENABLED"] == "true"))
func testICloudSync() async throws {
    // Only runs if ICLOUD_ENABLED env var is set
    // ...
}

@Test("Performance test", .disabled("Too slow for CI"))
func performanceBenchmark() async throws {
    // Disabled but documented why
    // ...
}
```

#### 3.4 Lifecycle Hooks

```swift
@Suite("Category Service Tests")
struct CategoryServiceTests {
    
    // Runs before ALL tests in this suite
    init() async throws {
        // Setup test database
        await setupTestDatabase()
    }
    
    // Runs after ALL tests in this suite
    deinit {
        // Cleanup
        Task {
            await cleanupTestDatabase()
        }
    }
    
    @Test("Create category")
    func createCategory() async throws {
        // Test uses shared setup from init()
    }
}
```

---

### Phase 4: Test Utilities & Helpers (Days 9-10)

#### 4.1 Test Data Builders

```swift
// TestHelpers.swift

import Foundation
@testable import OMOMoney

struct TestDataBuilder {
    static func createUser(
        name: String = "Test User",
        email: String = "test@example.com"
    ) async throws -> UserDomain {
        let useCase = AppDIContainer.shared.makeCreateUserUseCase()
        return try await useCase.execute(name: name, email: email)
    }
    
    static func createGroup(
        name: String = "Test Group",
        currency: String = "USD",
        user: UserDomain
    ) async throws -> GroupDomain {
        let useCase = AppDIContainer.shared.makeCreateGroupUseCase()
        return try await useCase.execute(
            name: name,
            currency: currency,
            userId: user.id
        )
    }
    
    static func createItemList(
        description: String = "Test Item List",
        date: Date = Date(),
        group: GroupDomain,
        category: CategoryDomain,
        paymentMethod: PaymentMethodDomain
    ) async throws -> ItemListDomain {
        let useCase = AppDIContainer.shared.makeCreateItemListUseCase()
        return try await useCase.execute(
            description: description,
            date: date,
            categoryId: category.id,
            paymentMethodId: paymentMethod.id,
            groupId: group.id
        )
    }
}
```

#### 4.2 Custom Expectations

```swift
// CustomExpectations.swift

import Testing

extension Confirmation {
    /// Expect a value to be within a range
    static func expectInRange<T: Comparable>(
        _ value: T,
        _ range: ClosedRange<T>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            range.contains(value),
            "Expected \(value) to be in range \(range)",
            sourceLocation: sourceLocation
        )
    }
    
    /// Expect a date to be recent (within last 5 seconds)
    static func expectRecent(
        _ date: Date,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let now = Date()
        let fiveSecondsAgo = now.addingTimeInterval(-5)
        #expect(
            date >= fiveSecondsAgo && date <= now,
            "Expected date to be recent, got \(date)",
            sourceLocation: sourceLocation
        )
    }
}
```

---

### Phase 5: Integration & Performance Tests (Days 11-14)

#### 5.1 End-to-End Flow Tests

```swift
@Suite("End-to-End User Flows", .tags(.integration, .e2e))
struct EndToEndFlowTests {
    
    @Test("Complete expense tracking flow")
    func completeExpenseFlow() async throws {
        // 1. Create user
        let user = try await TestDataBuilder.createUser()
        
        // 2. Create group
        let group = try await TestDataBuilder.createGroup(user: user)
        
        // 3. Create category
        let categoryUseCase = AppDIContainer.shared.makeCreateCategoryUseCase()
        let category = try await categoryUseCase.execute(
            name: "Groceries",
            color: "#FF0000",
            groupId: group.id
        )
        
        // 4. Create payment method
        let paymentMethodUseCase = AppDIContainer.shared.makeCreatePaymentMethodUseCase()
        let paymentMethod = try await paymentMethodUseCase.execute(
            name: "Credit Card",
            paymentType: "Credit",
            groupId: group.id
        )
        
        // 5. Create item list
        let itemList = try await TestDataBuilder.createItemList(
            description: "Weekly shopping",
            group: group,
            category: category,
            paymentMethod: paymentMethod
        )
        
        // 6. Add items
        let createItemUseCase = AppDIContainer.shared.makeCreateItemUseCase()
        let item1 = try await createItemUseCase.execute(
            description: "Milk",
            amount: 3.99,
            quantity: 2,
            itemListId: itemList.id,
            isPaid: true
        )
        
        let item2 = try await createItemUseCase.execute(
            description: "Bread",
            amount: 2.50,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: false
        )
        
        // 7. Verify total calculation
        let fetchItemsUseCase = AppDIContainer.shared.makeFetchItemsUseCase()
        let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
        
        #expect(items.count == 2)
        
        let total = items.reduce(0.0) { sum, item in
            sum + (Double(truncating: item.amount as NSNumber) * Double(item.quantity))
        }
        
        #expect(total == 10.48) // 3.99*2 + 2.50*1
    }
}
```

#### 5.2 Performance Tests

```swift
@Suite("Performance Tests", .tags(.performance))
struct PerformanceTests {
    
    @Test("Fetch 1000 item lists performs in < 1s", .timeLimit(.seconds(1)))
    func fetchLargeDataset() async throws {
        // Setup: Create 1000 item lists
        let user = try await TestDataBuilder.createUser()
        let group = try await TestDataBuilder.createGroup(user: user)
        let category = try await createTestCategory(in: group)
        let paymentMethod = try await createTestPaymentMethod(in: group)
        
        // Create 1000 item lists
        for i in 0..<1000 {
            let _ = try await TestDataBuilder.createItemList(
                description: "Item List \(i)",
                group: group,
                category: category,
                paymentMethod: paymentMethod
            )
        }
        
        // Test: Fetch should complete in < 1s
        let fetchUseCase = AppDIContainer.shared.makeFetchItemListsUseCase()
        let startTime = Date()
        
        let itemLists = try await fetchUseCase.execute(forGroupId: group.id)
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(itemLists.count == 1000)
        #expect(elapsed < 1.0, "Fetch took \(elapsed)s, expected < 1s")
    }
}
```

---

## 🎁 Benefits After Migration

### Test Code Quality

| Metric | Before (XCTest) | After (Swift Testing) |
|--------|-----------------|----------------------|
| Lines per test | ~20-30 | ~10-15 (50% reduction) |
| Setup boilerplate | `setUp()`/`tearDown()` required | Optional `init()`/`deinit()` |
| Async support | Expectations + callbacks | Native async/await |
| Parameterization | Duplicate test methods | Single test with `arguments:` |
| Error handling | Try/catch + `XCTAssertThrowsError` | `#expect(throws:)` |

### Developer Experience

✅ **Faster feedback** - Parallel test execution by default  
✅ **Better errors** - More context on what failed and why  
✅ **Easier to write** - Less ceremony, more focus on logic  
✅ **Type-safe tags** - Compile-time checked test organization  
✅ **Flexible execution** - Run subsets with tags

---

## 📊 Test Coverage Goals

### Minimum Coverage Targets

| Layer | Target Coverage | Priority |
|-------|----------------|----------|
| Domain Models | 90%+ | High |
| Use Cases | 85%+ | High |
| Repositories | 80%+ | High |
| ViewModels | 75%+ | Medium |
| Services | 70%+ | Medium |
| Views | 50%+ | Low (UI tests better) |

### Test Categories

```swift
// Define custom tags for organization
extension Tag {
    @Tag static var unit: Self
    @Tag static var integration: Self
    @Tag static var e2e: Self
    @Tag static var performance: Self
    @Tag static var viewModel: Self
    @Tag static var useCase: Self
    @Tag static var repository: Self
}

// Usage in tests
@Test(.tags(.unit, .useCase))
func testCreateUser() async throws { /* ... */ }

// Run only unit tests: swift test --filter .unit
// Skip slow tests: swift test --skip .performance
```

---

## 🎯 Example Test Suite Structure

```swift
// UserTests.swift
import Testing
@testable import OMOMoney

@Suite("User Domain Tests", .tags(.unit))
struct UserTests {
    
    @Test("User initializes with valid data")
    func userInitialization() {
        let user = UserDomain(
            id: UUID(),
            name: "John Doe",
            email: "john@example.com",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        #expect(user.name == "John Doe")
        #expect(user.email == "john@example.com")
        #expect(user.id != UUID()) // Has a unique ID
    }
    
    @Test(
        "User validates email format",
        arguments: [
            ("test@example.com", true),
            ("invalid-email", false),
            ("", false),
            ("test@", false)
        ]
    )
    func emailValidation(email: String, expectedValid: Bool) {
        let isValid = email.contains("@") && email.contains(".")
        #expect(isValid == expectedValid)
    }
}

// CreateUserUseCaseTests.swift
import Testing
@testable import OMOMoney

@Suite("Create User Use Case Tests", .tags(.unit, .useCase))
struct CreateUserUseCaseTests {
    
    let useCase: CreateUserUseCase
    
    init() async throws {
        useCase = AppDIContainer.shared.makeCreateUserUseCase()
    }
    
    @Test("Creates user with valid data")
    func createValidUser() async throws {
        let user = try await useCase.execute(
            name: "Test User",
            email: "test@example.com"
        )
        
        #expect(user.name == "Test User")
        #expect(user.email == "test@example.com")
        Confirmation.expectRecent(user.createdAt)
        Confirmation.expectRecent(user.updatedAt)
    }
    
    @Test("Fails with empty name")
    func failsWithEmptyName() async throws {
        await #expect(throws: ValidationError.self) {
            try await useCase.execute(name: "", email: "test@example.com")
        }
    }
    
    @Test("Fails with invalid email")
    func failsWithInvalidEmail() async throws {
        await #expect(throws: ValidationError.self) {
            try await useCase.execute(name: "Test", email: "invalid")
        }
    }
}

// DashboardViewModelTests.swift
import Testing
@testable import OMOMoney

@Suite("Dashboard ViewModel Tests", .tags(.integration, .viewModel))
struct DashboardViewModelTests {
    
    @Test("Calculates total spent correctly")
    func calculateTotalSpent() async throws {
        // Given
        let user = try await TestDataBuilder.createUser()
        let group = try await TestDataBuilder.createGroup(user: user)
        let category = try await createTestCategory(in: group)
        let paymentMethod = try await createTestPaymentMethod(in: group)
        
        let itemList = try await TestDataBuilder.createItemList(
            group: group,
            category: category,
            paymentMethod: paymentMethod
        )
        
        let createItemUseCase = AppDIContainer.shared.makeCreateItemUseCase()
        
        // Create 3 items: 10.00, 20.50, 5.25
        let _ = try await createItemUseCase.execute(
            description: "Item 1",
            amount: 10.00,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: true
        )
        
        let _ = try await createItemUseCase.execute(
            description: "Item 2",
            amount: 20.50,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: true
        )
        
        let _ = try await createItemUseCase.execute(
            description: "Item 3",
            amount: 5.25,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: true
        )
        
        // When
        let viewModel = DashboardViewModel(
            fetchItemListsUseCase: AppDIContainer.shared.makeFetchItemListsUseCase(),
            fetchItemsUseCase: AppDIContainer.shared.makeFetchItemsUseCase(),
            deleteItemListUseCase: AppDIContainer.shared.makeDeleteItemListUseCase(),
            getCurrentUserUseCase: AppDIContainer.shared.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: AppDIContainer.shared.makeFetchGroupsForUserUseCase(),
            fetchCategoriesUseCase: AppDIContainer.shared.makeFetchCategoriesUseCase(),
            toggleAllItemsPaidInListUseCase: AppDIContainer.shared.makeToggleAllItemsPaidInListUseCase()
        )
        
        await viewModel.loadDashboardData()
        
        // Then
        #expect(viewModel.totalSpent == 35.75) // 10.00 + 20.50 + 5.25
    }
}
```

---

## ⚠️ Common Migration Pitfalls

### 1. Forgetting async/await

```swift
// ❌ WRONG: XCTest pattern doesn't work
@Test
func testAsync() {
    let expectation = // ... NO! This doesn't exist in Swift Testing
}

// ✅ CORRECT: Use native async
@Test
func testAsync() async throws {
    let result = try await someAsyncFunction()
    #expect(result != nil)
}
```

### 2. Using XCTAssertEqual instead of #expect

```swift
// ❌ WRONG: XCTest assertion
#expect(value == expected)
XCTAssertEqual(value, expected) // This won't compile!

// ✅ CORRECT: Swift Testing assertion
#expect(value == expected)
```

### 3. Relying on test execution order

```swift
// ❌ WRONG: Tests run in parallel, order not guaranteed
@Test func step1() { /* ... */ }
@Test func step2() { /* Assumes step1 ran first */ }

// ✅ CORRECT: Each test is independent
@Test func completeWorkflow() async throws {
    // Do all steps in one test for integration
    await step1()
    await step2()
}
```

---

## 📅 Timeline & Milestones

| Days | Milestone | Deliverable |
|------|-----------|-------------|
| 1 | Setup | Swift Testing enabled, file structure created |
| 2-5 | Convert existing tests | All XCTest → Swift Testing |
| 6-8 | Add new test types | Parameterized, error, conditional tests |
| 9-10 | Test utilities | Helpers, builders, custom expectations |
| 11-14 | Integration tests | E2E flows, performance tests |

---

## ✅ Success Criteria

- [ ] All tests migrated to Swift Testing
- [ ] Test coverage ≥ 75% overall
- [ ] All tests pass consistently
- [ ] CI/CD pipeline updated
- [ ] Test execution time < 2 minutes
- [ ] Documentation updated with examples
- [ ] Team trained on Swift Testing patterns

---

## 📚 References

- [Swift Testing Documentation](https://developer.apple.com/documentation/Testing)
- [Meet Swift Testing (WWDC 2024)](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [Go Further with Swift Testing (WWDC 2024)](https://developer.apple.com/videos/play/wwdc2024/10195/)
- [Swift Testing on GitHub](https://github.com/apple/swift-testing)

---

**Next Steps:**
1. Audit existing tests (if any)
2. Create test plan for uncovered areas
3. Set up CI/CD for Swift Testing
4. Begin Phase 1: Setup

**Document Version:** 1.0  
**Last Updated:** April 15, 2026  
**Author:** AI Assistant
