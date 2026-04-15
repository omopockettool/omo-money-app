# Changelog - SwiftData Migration

All notable changes to the SwiftData migration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-04-15

> **New era: SwiftData + iOS 26**
> This version marks the beginning of the SwiftData migration. The app moves from
> Core Data + Domain model duplication to SwiftData `@Model` classes as the single
> source of truth. Core Data stack remains active in parallel until Phase 3.

### Added
- **SD*.swift** — 7 SwiftData `@Model` classes (`SDUser`, `SDGroup`, `SDUserGroup`, `SDCategory`, `SDPaymentMethod`, `SDItemList`, `SDItem`) with relationships, validations, computed properties, and `#if DEBUG` mock helpers
- **OMOMoneySchema.swift** — `SchemaV1` versioned schema registering all 7 models; `typealias OMOMoneySchema = SchemaV1`
- **ModelContainer+Shared.swift** — shared production container, preview container with seeded sample data, test container factory, `safeSave`/`safeRollback` helpers, `isEmpty()` and `getStatistics()` diagnostics

### Changed
- **OMOMoneyApp.swift** — added `import SwiftData`, initialized `ModelContainer.shared` alongside existing `PersistenceController`, injected `.modelContainer(modelContainer)` into the SwiftUI environment (Core Data stack unchanged)

### Fixed
- **ModelsSwiftData*.swift removed** — 8 duplicate SwiftData files (`ModelsSwiftDataUser`, `ModelsSwiftDataGroup`, etc.) that defined plain-named classes (`class ItemList`, `class Group`, …) conflicting with Core Data NSManagedObject entities were removed from the project and deleted; `SD*` files are the canonical models
- **`*+Mapping.swift` — `where Self: NSManagedObject` removed** from all 7 Core Data mapping extensions (`Category`, `Group`, `Item`, `ItemList`, `PaymentMethod`, `User`, `UserGroup`); the constraint is invalid on concrete class extensions

### Migration State at 1.0.0
```
Phase 1 — Preparation       ████████░░  ~60%
  ✅ 1.1  SwiftData models created (SD*)
  ✅ 1.2  ModelContainer+Shared configured
  ✅ 1.3  App entry point injected
  ⏳ 1.4  Migration script (CoreDataToSwiftDataMigrator)
Phase 2 — App Integration   ░░░░░░░░░░   0%
Phase 3 — Services Refactor ░░░░░░░░░░   0%
Phase 4 — ViewModels        ░░░░░░░░░░   0%
Phase 5 — Testing           ░░░░░░░░░░   0%
```

---

## [Unreleased]

### Phase 1: SwiftData Model Creation (Week 1) - IN PROGRESS

#### [2026-04-15] - Step 1.1-1.8: SwiftData Models Created

##### Added
- **User.swift** - SwiftData model for users
  - Unique ID with @Attribute(.unique)
  - Relationships to UserGroup (many-to-many)
  - Validation logic
  - Computed properties (groups, isOwnerOfAnyGroup)
  - Test mock helpers

- **Group.swift** - SwiftData model for groups
  - Unique ID with @Attribute(.unique)
  - Relationships to UserGroup, Category, PaymentMethod, ItemList
  - Validation logic
  - Computed properties (users, owner, default methods)
  - Test mock helpers

- **UserGroup.swift** - SwiftData junction table model
  - Unique ID with @Attribute(.unique)
  - Relationships to User and Group
  - Role management with enum and permissions
  - Permission checking methods
  - Test mock helpers

- **Category.swift** - SwiftData model for expense categories
  - Unique ID with @Attribute(.unique)
  - Relationships to Group and ItemList
  - Optional spending limits
  - Computed properties (spending calculations, limit tracking)
  - Test mock helpers

- **PaymentMethod.swift** - SwiftData model for payment methods
  - Unique ID with @Attribute(.unique)
  - Relationships to Group and ItemList
  - Payment type enum
  - Computed properties (spending by timeframe)
  - Test mock helpers

- **ItemList.swift** - SwiftData model for transactions/expenses
  - Unique ID with @Attribute(.unique)
  - Relationships to Group, Category, PaymentMethod, Item
  - Payment status tracking (paid/partial/unpaid)
  - Computed properties (totals, counts, status)
  - Convenience methods (toggle paid, add/remove items)
  - Test mock helpers

- **Item.swift** - SwiftData model for individual items
  - Unique ID with @Attribute(.unique)
  - Relationship to ItemList
  - Amount stored as Double (was Decimal in Domain)
  - Computed properties (totalAmount, formatted amounts)
  - Convenience methods (toggle paid, update quantity/amount)
  - Test mock helpers

- **OMOMoneySchema.swift** - Schema version management
  - SchemaV1 definition (baseline migration from Core Data)
  - All 7 models registered
  - Migration plan documentation
  - Type alias OMOMoneySchema = SchemaV1
  - Reserved SchemaV2 for future enhancements

##### Technical Details

**File Structure:**
```
Models/
└── SwiftData/
    ├── User.swift
    ├── Group.swift
    ├── UserGroup.swift
    ├── Category.swift
    ├── PaymentMethod.swift
    ├── ItemList.swift
    ├── Item.swift
    └── OMOMoneySchema.swift
```

**Key Design Decisions:**
1. **No Duplicate Domain Models**: SwiftData models replace both Core Data entities AND Domain models
2. **Decimal → Double**: Changed from Decimal to Double for SwiftData compatibility (Decimal in computed properties)
3. **Int32 → Int**: Simplified quantity types
4. **Optional Relationships**: All relationships are optional for nil-safety
5. **Automatic Inverse Management**: SwiftData handles inverse relationships automatically
6. **Delete Rules**: Cascade for ownership, nullify for references
7. **Unique IDs**: @Attribute(.unique) ensures database-level uniqueness

**Lines of Code:**
- User.swift: ~140 lines
- Group.swift: ~160 lines  
- UserGroup.swift: ~180 lines
- Category.swift: ~200 lines
- PaymentMethod.swift: ~190 lines
- ItemList.swift: ~220 lines
- Item.swift: ~190 lines
- OMOMoneySchema.swift: ~70 lines
- **Total: ~1,350 lines** (vs ~2,244 lines before with Domain + Core Data)

**Code Reduction: ~40%** just from model consolidation!

##### Next Steps
- [x] Create ModelContainer configuration ✅
- [ ] Update app entry point to use SwiftData
- [ ] Create preview containers for SwiftUI previews (✅ Already in ModelContainer+Shared)
- [ ] Write migration script from Core Data to SwiftData
- [ ] Create repository layer using ModelContext

---

#### [2026-04-15] - Step 1.2: ModelContainer Configuration Created

##### Added
- **ModelContainer+Shared.swift** - ModelContainer configuration and extensions
  - Shared production container (replaces PersistenceController.shared)
  - Preview container with sample data for SwiftUI previews
  - Test container factory for unit tests
  - ModelContext helper extensions (safeSave, safeRollback)
  - Migration helpers (isEmpty, getStatistics)
  - ContainerStatistics struct for monitoring

##### Technical Details

**Features:**
- ✅ **Production Container**: Persistent storage with optional iCloud sync
- ✅ **Preview Container**: In-memory with pre-populated sample data
- ✅ **Test Container**: In-memory, empty for isolated tests
- ✅ **Safe Operations**: Error handling for save/rollback
- ✅ **Migration Support**: isEmpty() and getStatistics() helpers
- ✅ **Statistics Tracking**: Monitor data counts across all models

**Sample Data in Previews:**
- 1 User (Preview User)
- 1 Group (Preview Group)
- 1 UserGroup relationship
- 1 Category (Groceries with $500 limit)
- 1 PaymentMethod (Credit Card)
- 1 ItemList (Weekly Shopping)
- 2 Items (Milk: $3.99×2 paid, Bread: $2.50×1 unpaid)

**Lines of Code:**
- ModelContainer+Shared.swift: ~280 lines

##### Next Steps
- [ ] Update OMOMoneyApp.swift to use ModelContainer.shared
- [ ] Remove PersistenceController.swift (later phase)
- [ ] Test preview functionality
- [ ] Begin migration script creation

---

## Template for Future Entries

```markdown
#### [YYYY-MM-DD] - Brief Description

##### Added
- Feature/file descriptions

##### Changed
- Modifications to existing code

##### Deprecated
- Features marked for removal

##### Removed
- Deleted code/features

##### Fixed
- Bug fixes

##### Security
- Security improvements
```

---

**Migration Progress:**
- [x] Phase 1, Step 1: Create SwiftData models (8/8 models complete)
- [ ] Phase 1, Step 2: Create ModelContainer configuration
- [ ] Phase 1, Step 3: Create preview containers
- [ ] Phase 2: Update app structure
- [ ] Phase 3: Simplify services layer
- [ ] Phase 4: Update ViewModels
- [ ] Phase 5: Testing & migration

**Status:** ✅ Step 1 Complete - SwiftData models defined  
**Next:** Create ModelContainer and configuration
