# OMOMoney - Clean Architecture Project Structure

## 🏗️ **Clean Architecture Implementation v1.0.0**

This document describes the **Clean Architecture** structure implemented on November 27, 2025.

---

## 🔄 **Architecture Flow**

### **Dependency Direction**
```
Presentation → Domain ← Data
                ↑
          Infrastructure
                ↑
          Application
```

**Rule**: All dependencies point **toward** the Domain layer.
- ✅ Presentation depends on Domain
- ✅ Data depends on Domain
- ✅ Infrastructure can be used by any layer
- ✅ Application orchestrates everything
- ❌ Domain has **ZERO** dependencies

---

## 📋 **Layer Responsibilities**

### 1️⃣ **Application Layer**
**Purpose**: App configuration and dependency injection
- App entry point (`OMOMoneyApp.swift`)
- DI container setup
- Global configuration
- **Dependencies**: All layers

### 2️⃣ **Domain Layer** (Core)
**Purpose**: Pure business logic
- **Entities**: Domain models (immutable, pure Swift)
- **Protocols**: Contracts for repositories and services
- **Use Cases**: Business operations (one per operation)
- **Errors**: Domain-specific errors
- **Dependencies**: **NONE** (Foundation only)

### 3️⃣ **Data Layer**
**Purpose**: Data persistence and access
- **Repositories**: Implement domain protocols
- **Services**: Core Data operations
- **Mappings**: Entity ↔ Domain conversions
- **Dependencies**: Domain

### 4️⃣ **Presentation Layer**
**Purpose**: User interface
- **Views**: SwiftUI components
- **ViewModels**: Presentation logic (@MainActor)
- **Scenes**: Feature-based organization
- **Dependencies**: Domain

### 5️⃣ **Infrastructure Layer**
**Purpose**: Cross-cutting utilities
- Cache management
- Helpers and utilities
- Extensions
- Constants
- **Dependencies**: Can be used by any layer

---

## ✨ **Key Features**

### ✅ **Single Source of Truth**
All protocols consolidated in `Domain/Protocols/`:
- Repository protocols: 7 files
- Service protocols: 7 files
- Easy to find and maintain

### ✅ **Feature-Based Organization**
Presentation layer organized by feature:
- Dashboard, User, Group, ItemList, Category, PaymentMethod, Item
- Each feature has its own Views and ViewModels

### ✅ **Clean Separation**
- Domain: Pure Swift, no dependencies
- Data: Implementation details hidden
- Presentation: UI concerns only
- Infrastructure: Shared utilities

### ✅ **Testability**
Each layer can be tested independently:
- Domain: Pure unit tests
- Data: Integration tests with in-memory Core Data
- Presentation: UI tests with mocked use cases

---

## 🎯 **Best Practices**

### DO ✅
1. Keep Domain pure (Foundation only)
2. Use protocols for abstraction
3. Inject dependencies
4. Organize by feature in Presentation
5. Test each layer independently

### DON'T ❌
1. Don't mix layers
2. Don't skip use cases
3. Don't put business logic in Views
4. Don't import Core Data in ViewModels
5. Don't create circular dependencies

---

## 📚 **Documentation**

For more details, see:
- `CLEAN_ARCHITECTURE_GUIDE.md` - Complete architecture explanation
- `ARCHITECTURE_DIAGRAMS.md` - Visual diagrams
- `IMPLEMENTATION_GUIDE.md` - Step-by-step guide
- `QUICK_START.md` - Quick reference

---

## 🚀 **Migration History**

**Version 0.16.0** (November 27, 2025)
- Complete reorganization following Clean Architecture
- Consolidated protocols in Domain/Protocols/
- Feature-based Presentation organization
- 5-layer architecture implementation
- Zero breaking changes

---

**Last Updated**: November 27, 2025
**Architecture Version**: 1.0.0
**Status**: ✅ Complete and Stable
