# 📚 SwiftData Quick Reference Guide

**For OMOMoney Development Team**  
**Created:** April 15, 2026  
**Purpose:** Quick reference for working with new SwiftData models

---

## 🚀 Quick Start

### Using SwiftData Models in Your Code

```swift
import SwiftData

// Get the model context from environment
@Environment(\.modelContext) private var modelContext

// Or inject in ViewModels
@MainActor
class MyViewModel {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
```

---

## 📋 Common Operations

### 1. Creating Objects

```swift
// Create a new user
let user = User(name: "John Doe", email: "john@example.com")
modelContext.insert(user)
try modelContext.save()

// Create with relationships
let group = Group(name: "Family", currency: "USD")
modelContext.insert(group)

let userGroup = UserGroup(role: "owner")
userGroup.user = user
userGroup.group = group
modelContext.insert(userGroup)

try modelContext.save()
```

### 2. Fetching Data

```swift
// Fetch all users
let descriptor = FetchDescriptor<User>()
let users = try modelContext.fetch(descriptor)

// Fetch with predicate
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.email.contains("@example.com") }
)
let users = try modelContext.fetch(descriptor)

// Fetch with sorting
let descriptor = FetchDescriptor<User>(
    sortBy: [SortDescriptor(\.name)]
)
let users = try modelContext.fetch(descriptor)
```

### 3. Updating Objects

```swift
// Fetch object
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.id == userId }
)
guard let user = try modelContext.fetch(descriptor).first else { return }

// Modify properties
user.name = "Jane Doe"
user.lastModifiedAt = Date()

// Save changes
try modelContext.save()
```

### 4. Deleting Objects

```swift
// Delete a single object
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.id == userId }
)
if let user = try modelContext.fetch(descriptor).first {
    modelContext.delete(user)
    try modelContext.save()
}

// Delete with cascade (automatic via @Relationship)
// When you delete a Group, all its Categories, PaymentMethods, etc. are deleted
modelContext.delete(group) // Cascades to related objects
try modelContext.save()
```

---

## 🎯 Using @Query in SwiftUI Views

```swift
import SwiftData

struct UserListView: View {
    // Automatic data fetching and updates
    @Query var users: [User]
    
    // With sorting
    @Query(sort: \User.name) var sortedUsers: [User]
    
    // With filtering
    @Query(
        filter: #Predicate<User> { $0.email.contains("@gmail.com") },
        sort: \User.name
    )
    var gmailUsers: [User]
    
    var body: some View {
        List(users) { user in
            Text(user.name)
        }
    }
}
```

---

## 🔍 Type-Safe Predicates

### Before (Core Data - Runtime Errors)
```swift
// ❌ String-based - typos cause runtime crashes
let predicate = NSPredicate(format: "name == %@", userName)
```

### After (SwiftData - Compile-Time Safety)
```swift
// ✅ Type-safe - typos caught at compile time
let predicate = #Predicate<User> { $0.name == userName }

// ✅ Complex predicates with logic
let predicate = #Predicate<User> { user in
    user.name.contains("John") && user.email.contains("@example.com")
}

// ✅ Relationship navigation
let predicate = #Predicate<ItemList> { itemList in
    itemList.group?.name == "Family" && itemList.date > startDate
}
```

---

## 🧪 Testing with SwiftData

### Unit Tests

```swift
import Testing
import SwiftData
@testable import OMOMoney

@Test("Create user with valid data")
func testCreateUser() async throws {
    // Use test container
    let container = ModelContainer.test()
    let context = container.mainContext
    
    // Create user
    let user = User(name: "Test", email: "test@example.com")
    context.insert(user)
    try context.save()
    
    // Verify
    let descriptor = FetchDescriptor<User>()
    let users = try context.fetch(descriptor)
    
    #expect(users.count == 1)
    #expect(users.first?.name == "Test")
}
```

### SwiftUI Previews

```swift
#Preview {
    UserListView()
        .modelContainer(ModelContainer.preview) // ✅ Includes sample data
}
```

---

## 📊 Available Models

### User
```swift
let user = User(name: "John", email: "john@example.com")
// Properties: id, name, email, createdAt, lastModifiedAt
// Relationships: userGroups → [UserGroup]
```

### Group
```swift
let group = Group(name: "Family", currency: "USD")
// Properties: id, name, currency, createdAt, lastModifiedAt
// Relationships: userGroups, categories, paymentMethods, itemLists
```

### Category
```swift
let category = Category(
    name: "Groceries",
    color: "#FF6B6B",
    icon: "cart.fill",
    limit: 500.0
)
// Properties: id, name, color, icon, isDefault, limit, limitFrequency
// Relationships: group, itemLists
// Computed: totalSpent(), isOverLimit, limitUsagePercentage
```

### PaymentMethod
```swift
let method = PaymentMethod(
    name: "Credit Card",
    type: "card",
    icon: "creditcard.fill"
)
// Properties: id, name, type, icon, color, isActive, isDefault
// Relationships: group, itemLists
// Computed: totalSpent()
```

### ItemList
```swift
let itemList = ItemList(
    itemListDescription: "Weekly Shopping",
    date: Date()
)
// Properties: id, itemListDescription, date, createdAt, lastModifiedAt
// Relationships: group, category, paymentMethod, items
// Computed: totalAmount, totalPaidAmount, totalUnpaidAmount, paymentStatus
```

### Item
```swift
let item = Item(
    itemDescription: "Milk",
    amount: 3.99,
    quantity: 2,
    isPaid: true
)
// Properties: id, itemDescription, amount, quantity, isPaid, createdAt
// Relationships: itemList
// Computed: totalAmount, formattedAmount()
```

---

## 🎨 Validation

All models include validation:

```swift
// Check if valid
if user.isValid {
    try modelContext.save()
}

// Validate and throw errors
do {
    try user.validate()
    try modelContext.save()
} catch ValidationError.emptyName {
    // Handle error
} catch {
    // Handle other errors
}
```

---

## 🧰 Helper Methods

### ModelContext Extensions

```swift
// Safe save (only saves if changes exist)
try modelContext.safeSave()

// Safe rollback
modelContext.safeRollback()
```

### Container Statistics

```swift
let stats = ModelContainer.shared.getStatistics()
print(stats.description)
// Output:
// 📊 Container Statistics:
// - Users: 5
// - Groups: 3
// - Categories: 12
// - Payment Methods: 4
// - Item Lists: 150
// - Items: 823
```

---

## 🔄 Relationships

### Automatic Inverse Management

```swift
// Set relationship in ONE direction
category.group = group

// SwiftData automatically updates inverse
// group.categories now includes category ✅

// Same for many-to-many
userGroup.user = user
userGroup.group = group

// Both user.userGroups and group.userGroups updated ✅
```

### Delete Rules

- **Cascade**: Deleting parent deletes children
  ```swift
  // Delete group → deletes categories, paymentMethods, itemLists
  modelContext.delete(group)
  ```

- **Nullify**: Deleting referenced object just nullifies reference
  ```swift
  // Delete category → itemLists.category becomes nil (not deleted)
  modelContext.delete(category)
  ```

---

## 🧪 Test Mocks

Every model has mock helpers:

```swift
#if DEBUG
// Create with defaults
let user = User.mock()

// Create with custom values
let user = User.mock(
    name: "Custom Name",
    email: "custom@example.com"
)

// Use in previews
#Preview {
    UserDetailView(user: User.mock())
        .modelContainer(ModelContainer.preview)
}
#endif
```

---

## ⚠️ Common Gotchas

### 1. Amounts are Double (not Decimal)

```swift
// ❌ Don't use Decimal for storage
var amount: Decimal // Compile error

// ✅ Use Double for storage, Decimal for calculations
var amount: Double
var amountDecimal: Decimal {
    Decimal(amount)
}
```

### 2. All Relationships are Optional

```swift
// ❌ Non-optional relationship doesn't work
var group: Group // Compile error

// ✅ All relationships must be optional
var group: Group?
```

### 3. Save After Changes

```swift
// ❌ Changes won't persist
user.name = "New Name"
// Forgot to save!

// ✅ Always save
user.name = "New Name"
try modelContext.save()
```

### 4. Fetch Before Delete

```swift
// ❌ Don't delete by ID directly
modelContext.delete(userId) // Doesn't work

// ✅ Fetch first, then delete
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.id == userId }
)
if let user = try modelContext.fetch(descriptor).first {
    modelContext.delete(user)
    try modelContext.save()
}
```

---

## 📚 Additional Resources

### Documentation
- [Migration Plan](./MIGRATION_PLAN_SWIFTDATA.md) - Full migration strategy
- [Changelog](./SWIFTDATA_MIGRATION_CHANGELOG.md) - What changed when
- [Progress Tracker](./MIGRATION_PROGRESS.md) - Current status

### Apple Documentation
- [SwiftData Overview](https://developer.apple.com/documentation/SwiftData)
- [Model Your Schema](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [SwiftData Predicates](https://developer.apple.com/documentation/SwiftData/Filtering-and-sorting-persistent-data)

---

## 🆘 Need Help?

### Common Questions

**Q: How do I get the ModelContext?**  
A: In views: `@Environment(\.modelContext)`, in ViewModels: inject via init

**Q: How do I fetch data?**  
A: Use `FetchDescriptor` with `modelContext.fetch()` or `@Query` in views

**Q: How do I handle errors?**  
A: Wrap in `do-catch`, check `ValidationError` enum

**Q: Where are the old Domain models?**  
A: SwiftData models replace them! No separate domain models needed.

**Q: Can I still use Core Data?**  
A: Yes! During migration, both coexist. Eventually Core Data will be removed.

---

**Questions? Check the migration docs or ask the team!**

---

*Last Updated: April 15, 2026*  
*SwiftData Migration Phase 1*
