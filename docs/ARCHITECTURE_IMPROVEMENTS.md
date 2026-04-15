# 🏗️ Architecture Improvements Plan

**Priority:** HIGH  
**Status:** Planning Phase  
**Estimated Effort:** 2-3 weeks  
**Focus:** Clean Architecture refinements, Swift Concurrency best practices

---

## 📋 Executive Summary

OMOMoney already follows **Clean Architecture** principles with a well-structured layers:
- **Presentation Layer**: ViewModels, Views
- **Domain Layer**: Use Cases, Domain Models
- **Data Layer**: Repositories, Services

However, there are opportunities to further improve the architecture by:
1. Fully embracing Swift Concurrency (actors, sendable)
2. Eliminating remaining Core Data coupling
3. Simplifying dependency injection
4. Improving error handling
5. Enhancing testability

---

## 🎯 Current Architecture Analysis

### ✅ What's Good

```
Current Architecture (Clean Architecture):

┌─────────────────────────────────────────────────┐
│ Presentation Layer                              │
│  - DashboardView                                │
│  - DashboardViewModel (@MainActor)              │
│  - UserListViewModel                            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Domain Layer                                    │
│  - Use Cases (CreateUserUseCase, etc.)         │
│  - Domain Models (UserDomain, GroupDomain)     │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Data Layer                                      │
│  - Repositories (UserRepository)                │
│  - Services (UserService, CategoryService)     │
│  - Core Data Entities                           │
└─────────────────────────────────────────────────┘
```

**Strengths:**
- ✅ Clear separation of concerns
- ✅ Use Cases isolate business logic
- ✅ ViewModels don't directly access persistence
- ✅ Domain models separate from Core Data entities
- ✅ Dependency injection via DI Container

### ⚠️ What Can Be Improved

1. **Thread Safety Issues**
   - Services use `context.perform` but not always consistently
   - Some properties are not thread-safe
   - Manual synchronization in places

2. **Core Data Coupling**
   - Services still tightly coupled to `NSManagedObjectContext`
   - Complex entity ↔ domain model conversions
   - Cache management is manual and error-prone

3. **Error Handling**
   - Generic `RepositoryError` enum
   - Errors not always descriptive
   - No structured error recovery

4. **Dependency Injection**
   - `AppDIContainer` is good but can be simplified
   - Factory methods are verbose
   - Hard to mock for testing

---

## 🚀 Phase 1: Actor-Based Repositories (Week 1)

### Why Actors?

Swift actors provide:
- ✅ **Automatic thread safety** - No manual synchronization
- ✅ **Compiler-enforced isolation** - Prevents data races
- ✅ **Better async/await integration** - Natural async code
- ✅ **Performance** - Optimized for concurrency

### Migration to Actors

```swift
// BEFORE: Repository with manual context management
class UserRepository: UserRepositoryProtocol {
    private let service: UserServiceProtocol
    
    init(service: UserServiceProtocol) {
        self.service = service
    }
    
    func getUser(byId id: UUID) async throws -> UserDomain? {
        return try await service.getUser(byId: id)
    }
}

// AFTER: Actor-based repository (Thread-safe by default!)
actor UserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext // ✅ After SwiftData migration
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getUser(byId id: UUID) async throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func createUser(name: String, email: String) async throws -> User {
        let user = User(name: name, email: email)
        modelContext.insert(user)
        try modelContext.save()
        return user
    }
    
    // ✅ All methods automatically isolated to actor's executor
}
```

### Benefits

| Before | After |
|--------|-------|
| Manual `context.perform` blocks | Automatic actor isolation |
| Risk of data races | Compile-time safety |
| Complex threading logic | Simple async/await |
| Hard to test thread safety | Easy to test in isolation |

---

## 🧩 Phase 2: Simplified Dependency Injection (Week 1)

### Current DI Container Issues

```swift
// Current: Verbose factory methods
class AppDIContainer {
    func makeCreateUserUseCase() -> CreateUserUseCase {
        let context = PersistenceController.shared.container.viewContext
        let userService = UserService(context: context)
        let userRepository = UserRepository(service: userService)
        return CreateUserUseCase(repository: userRepository)
    }
    
    // ... 20+ similar methods
}
```

**Problems:**
- Lots of boilerplate
- Hard to maintain
- Manual dependency wiring
- Difficult to test

### Solution: Protocol-Based DI with Property Wrappers

```swift
// NEW: Dependency property wrapper
@propertyWrapper
struct Injected<T> {
    private var dependency: T
    
    init() {
        guard let resolved = DependencyContainer.shared.resolve(T.self) else {
            fatalError("Failed to resolve dependency: \(T.self)")
        }
        self.dependency = resolved
    }
    
    var wrappedValue: T {
        get { dependency }
        mutating set { dependency = newValue }
    }
}

// NEW: Simplified DI Container
@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()
    
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]
    
    private init() {
        registerDependencies()
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = ObjectIdentifier(type)
        singletons[key] = instance
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)
        
        // Check singletons first
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Create from factory
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    private func registerDependencies() {
        let modelContext = ModelContainer.shared.mainContext
        
        // Register repositories as actors
        register(UserRepository.self) {
            UserRepository(modelContext: modelContext)
        }
        
        register(GroupRepository.self) {
            GroupRepository(modelContext: modelContext)
        }
        
        // Register use cases
        register(CreateUserUseCase.self) {
            CreateUserUseCase(repository: self.resolve(UserRepository.self)!)
        }
        
        register(GetCurrentUserUseCase.self) {
            GetCurrentUserUseCase(repository: self.resolve(UserRepository.self)!)
        }
        
        // ... etc
    }
}

// USAGE: Simple property wrapper
@MainActor
class DashboardViewModel {
    @Injected private var fetchItemListsUseCase: FetchItemListsUseCase
    @Injected private var deleteItemListUseCase: DeleteItemListUseCase
    @Injected private var getCurrentUserUseCase: GetCurrentUserUseCase
    
    // ✅ No manual initialization needed!
    // ✅ Dependencies automatically resolved
    // ✅ Easy to mock for testing
}
```

---

## 🎯 Phase 3: Structured Error Handling (Week 2)

### Current Error Handling Issues

```swift
// Current: Generic errors
enum RepositoryError: Error {
    case notFound
    case saveFailed
    case deleteFailed
}

// Usage
throw RepositoryError.saveFailed // ❌ No context about what failed
```

### Solution: Structured Error Types

```swift
// NEW: Domain-specific errors with context
protocol AppError: Error, LocalizedError {
    var title: String { get }
    var message: String { get }
    var recoveryOptions: [RecoveryOption] { get }
}

enum RecoveryOption {
    case retry
    case cancel
    case contactSupport
    case viewLogs
}

// User-specific errors
enum UserError: AppError {
    case userNotFound(userId: UUID)
    case invalidEmail(String)
    case emptyName
    case duplicateUser(name: String)
    case saveFailed(underlying: Error)
    
    var title: String {
        switch self {
        case .userNotFound: return "User Not Found"
        case .invalidEmail: return "Invalid Email"
        case .emptyName: return "Name Required"
        case .duplicateUser: return "User Already Exists"
        case .saveFailed: return "Save Failed"
        }
    }
    
    var message: String {
        switch self {
        case .userNotFound(let userId):
            return "No user found with ID: \(userId.uuidString.prefix(8))"
        case .invalidEmail(let email):
            return "The email '\(email)' is not valid"
        case .emptyName:
            return "User name cannot be empty"
        case .duplicateUser(let name):
            return "A user named '\(name)' already exists"
        case .saveFailed(let error):
            return "Failed to save user: \(error.localizedDescription)"
        }
    }
    
    var recoveryOptions: [RecoveryOption] {
        switch self {
        case .userNotFound: return [.cancel, .contactSupport]
        case .invalidEmail, .emptyName: return [.cancel]
        case .duplicateUser: return [.cancel]
        case .saveFailed: return [.retry, .cancel, .viewLogs]
        }
    }
    
    var errorDescription: String? { message }
    var failureReason: String? { title }
}

// ItemList-specific errors
enum ItemListError: AppError {
    case itemListNotFound(id: UUID)
    case invalidDate
    case categoryNotFound(categoryId: UUID)
    case paymentMethodNotFound(paymentMethodId: UUID)
    case saveFailed(underlying: Error)
    
    // ... similar implementation
}

// Generic data errors
enum DataError: AppError {
    case fetchFailed(entity: String, underlying: Error)
    case saveFailed(entity: String, underlying: Error)
    case deleteFailed(entity: String, underlying: Error)
    case corruptedData(entity: String)
    
    // ... similar implementation
}
```

### Error Handling in Views

```swift
// Enhanced error display
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        content
            .alert(
                error?.title ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                // Recovery options as buttons
                if let error = error {
                    ForEach(error.recoveryOptions, id: \.self) { option in
                        Button(option.title) {
                            handleRecovery(option, for: error)
                        }
                    }
                }
            } message: {
                if let error = error {
                    Text(error.message)
                }
            }
    }
    
    private func handleRecovery(_ option: RecoveryOption, for error: AppError) {
        switch option {
        case .retry:
            // Implement retry logic
            break
        case .cancel:
            self.error = nil
        case .contactSupport:
            // Open support contact
            break
        case .viewLogs:
            // Show error logs
            break
        }
    }
}

extension RecoveryOption {
    var title: String {
        switch self {
        case .retry: return "Retry"
        case .cancel: return "OK"
        case .contactSupport: return "Contact Support"
        case .viewLogs: return "View Logs"
        }
    }
}

// Usage in View
struct DashboardView: View {
    @State private var error: AppError?
    
    var body: some View {
        // ... content
        .modifier(ErrorAlertModifier(error: $error))
    }
}
```

---

## 🧪 Phase 4: Enhanced Testability (Week 2)

### Test-Friendly Architecture

```swift
// BEFORE: Hard to test (tightly coupled)
class DashboardViewModel {
    private let fetchItemListsUseCase: FetchItemListsUseCase
    
    init() {
        // ❌ Hard-coded dependency - can't inject mock
        let container = AppDIContainer.shared
        self.fetchItemListsUseCase = container.makeFetchItemListsUseCase()
    }
}

// AFTER: Protocol-based testing
protocol FetchItemListsUseCaseProtocol {
    func execute(forGroupId groupId: UUID) async throws -> [ItemList]
}

class FetchItemListsUseCase: FetchItemListsUseCaseProtocol {
    // ... implementation
}

class DashboardViewModel {
    private let fetchItemListsUseCase: FetchItemListsUseCaseProtocol
    
    // ✅ Dependency injection - easy to mock
    init(fetchItemListsUseCase: FetchItemListsUseCaseProtocol) {
        self.fetchItemListsUseCase = fetchItemListsUseCase
    }
}
```

### Mock Implementations for Testing

```swift
// Test mock implementation
@MainActor
class MockFetchItemListsUseCase: FetchItemListsUseCaseProtocol {
    var stubbedItemLists: [ItemList] = []
    var shouldThrowError = false
    var executeCalled = false
    
    func execute(forGroupId groupId: UUID) async throws -> [ItemList] {
        executeCalled = true
        
        if shouldThrowError {
            throw ItemListError.itemListNotFound(id: groupId)
        }
        
        return stubbedItemLists
    }
}

// Usage in tests
@Test("Dashboard loads item lists")
func dashboardLoadsItemLists() async throws {
    // Given
    let mockUseCase = MockFetchItemListsUseCase()
    mockUseCase.stubbedItemLists = [
        ItemList(id: UUID(), description: "Test", date: Date()),
        ItemList(id: UUID(), description: "Test 2", date: Date())
    ]
    
    let viewModel = DashboardViewModel(fetchItemListsUseCase: mockUseCase)
    
    // When
    await viewModel.loadDashboardData()
    
    // Then
    #expect(mockUseCase.executeCalled)
    #expect(viewModel.itemLists.count == 2)
}

@Test("Dashboard handles fetch error")
func dashboardHandlesError() async throws {
    // Given
    let mockUseCase = MockFetchItemListsUseCase()
    mockUseCase.shouldThrowError = true
    
    let viewModel = DashboardViewModel(fetchItemListsUseCase: mockUseCase)
    
    // When
    await viewModel.loadDashboardData()
    
    // Then
    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.itemLists.isEmpty)
}
```

---

## 📊 Phase 5: Performance Monitoring & Optimization (Week 3)

### Enhanced Performance Monitor

```swift
// IMPROVED: Actor-based performance monitor (thread-safe!)
@MainActor
@Observable
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private(set) var metrics: PerformanceMetrics = PerformanceMetrics()
    private var operationStartTimes: [String: Date] = [:]
    
    // ✅ Track async operations with automatic timing
    func track<T>(_ operationName: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        
        defer {
            let duration = Date().timeIntervalSince(startTime)
            recordMetric(operationName: operationName, duration: duration)
        }
        
        return try await operation()
    }
    
    private func recordMetric(operationName: String, duration: TimeInterval) {
        // Record performance data
        // ...
    }
}

// Usage
let items = await PerformanceMonitor.shared.track("FetchItems") {
    try await fetchItemsUseCase.execute(forItemListId: itemListId)
}
```

### Automatic Performance Alerts

```swift
// Alert developers to slow operations
extension PerformanceMonitor {
    func checkThresholds() {
        let slowOperations = metrics.operationMetrics.filter { 
            $0.value.averageDuration > 0.5 // 500ms threshold
        }
        
        if !slowOperations.isEmpty {
            print("⚠️ Slow operations detected:")
            for (name, metric) in slowOperations {
                print("  - \(name): \(metric.averageDuration)s average")
            }
            
            // Could send to analytics service
            // Analytics.logEvent("slow_operation", parameters: ...)
        }
    }
}
```

---

## 🎯 Phase 6: Sendable Conformance (Week 3)

### Why Sendable Matters

Swift 6 introduces strict concurrency checking. Making types `Sendable` ensures they're safe to pass between actors/tasks.

```swift
// Domain models should be Sendable (value types or immutable)
struct User: Sendable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
    let updatedAt: Date
}

struct ItemList: Sendable {
    let id: UUID
    let description: String
    let date: Date
    let categoryId: UUID
    let paymentMethodId: UUID
    let groupId: UUID
}

// Use Cases should be Sendable (stateless)
actor CreateUserUseCase: Sendable {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute(name: String, email: String) async throws -> User {
        // Validation
        guard !name.isEmpty else {
            throw UserError.emptyName
        }
        
        guard email.contains("@") else {
            throw UserError.invalidEmail(email)
        }
        
        // Create user
        return try await repository.createUser(name: name, email: email)
    }
}
```

---

## 🎁 Benefits Summary

### Code Quality Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Thread safety | Manual locks | Actor-isolated | Compile-time safety |
| DI boilerplate | ~20 factory methods | Property wrapper | 90% reduction |
| Error context | Generic errors | Structured errors | Rich debugging info |
| Test coverage | Hard to mock | Protocol-based | 100% testable |
| Performance visibility | Manual timing | Automatic tracking | Always monitored |

### Architecture Benefits

✅ **Thread Safety** - Actors prevent data races  
✅ **Testability** - Protocol-based DI makes mocking easy  
✅ **Error Handling** - Rich error context aids debugging  
✅ **Performance** - Automatic monitoring catches regressions  
✅ **Maintainability** - Less boilerplate, clearer code  
✅ **Swift 6 Ready** - Sendable conformance prepares for strict concurrency

---

## ⚠️ Migration Risks & Mitigation

### Risk 1: Breaking Changes from Actor Isolation

**Issue:** Converting to actors changes API signatures (all methods become async)

**Mitigation:**
- Use `@preconcurrency` for gradual migration
- Add extension methods to bridge old/new APIs
- Update in phases, one repository at a time

### Risk 2: Performance Impact of Actor Hopping

**Issue:** Crossing actor boundaries has overhead

**Mitigation:**
- Batch operations to minimize actor transitions
- Use local variables for repeated access
- Profile with Instruments to identify hotspots

### Risk 3: Testing Infrastructure Changes

**Issue:** Mocking actors requires new patterns

**Mitigation:**
- Create mock implementations incrementally
- Use protocols for all actor-based types
- Document testing patterns in README

---

## 📅 Timeline & Milestones

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1 | Actor-based repositories | All repositories converted to actors |
| 1 | Simplified DI | Property wrapper DI implemented |
| 2 | Structured errors | Domain-specific error types |
| 2 | Enhanced testability | Protocol-based mocks created |
| 3 | Performance monitoring | Automatic tracking in place |
| 3 | Sendable conformance | All types Sendable-compatible |

---

## ✅ Success Criteria

- [ ] All repositories are actors
- [ ] DI uses property wrappers
- [ ] Domain-specific error types for all domains
- [ ] Test coverage ≥ 80%
- [ ] All types conform to Sendable
- [ ] Performance regression tests pass
- [ ] No data race warnings in Xcode
- [ ] Documentation updated

---

## 📚 References

- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Actors](https://developer.apple.com/documentation/swift/actor)
- [Sendable](https://developer.apple.com/documentation/swift/sendable)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift Error Handling](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)

---

**Next Steps:**
1. Review current DI Container usage
2. Identify repositories for actor conversion
3. Create error type hierarchy
4. Set up testing infrastructure

**Document Version:** 1.0  
**Last Updated:** April 15, 2026  
**Author:** AI Assistant
