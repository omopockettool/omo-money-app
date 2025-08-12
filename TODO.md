# OMOMoney - SwiftUI Expense Tracker App Development TODO

## 🚨 REGLAS ESTRICTAS DE DESARROLLO - OBLIGATORIAS

### 📱 VERSIÓN DE PLATAFORMA - OBLIGATORIO
- **iOS Target**: iOS 18.5+ (2025)
- **SwiftUI**: Usar APIs más modernas disponibles
- **Compatibilidad**: No usar APIs deprecadas

### 🏗️ ARQUITECTURA MVVM - NO NEGOCIABLE
- **Views**: ❌ NO contienen lógica, ❌ NO cálculos, ❌ NO formateo, ✅ SOLO SwiftUI Views
- **ViewModels**: ❌ NO contienen UI, ✅ SOLO lógica de negocio, ✅ @MainActor, ✅ @Published
- **Models**: ❌ NO contienen lógica, ✅ SOLO entidades Core Data

### 🧵 THREADING - CRÍTICO
- **Main Thread**: ✅ SOLO UI, ✅ navegación, ✅ gestos, ✅ animaciones
- **Background Thread**: ✅ Core Data CRUD, ✅ cálculos complejos, ✅ filtros pesados
- **Patrón obligatorio**: `DispatchQueue.global` → operación pesada → `DispatchQueue.main.async`

### 📱 SWIFTUI - REACTIVIDAD AUTOMÁTICA (iOS 18.5+)
- ✅ Usar `@Published` - SwiftUI se redibuja automáticamente
- ❌ NO usar Timers para delays artificiales
- ❌ NO usar `Task.sleep` para esperas
- ❌ NO usar callbacks manuales (a menos que sea absolutamente necesario)
- ✅ Usar nueva sintaxis de `onChange` - `{ oldValue, newValue in }`
- ✅ Usar `@Observable` macro moderno (opcional)
- ✅ Usar `NavigationStack` moderno

### 🚫 PROHIBIDO
- Operaciones pesadas en main thread
- Lógica de negocio en Views
- UI elements en ViewModels
- Delays artificiales o polling

## Project Overview
Building a native iOS personal expense tracker app using SwiftUI (iOS 18.5+) with STRICT MVVM architecture, Core Data persistence, and NavigationStack navigation building into the view model for simplicity.

## Development Strategy
- **Incremental Development**: Small, focused commits for each feature
- **MVVM First**: All business logic in ViewModels, Views only display
- **Core Data Foundation**: Start with data model, build UI on top
- **Test-Driven**: Unit tests for each component
- **Physical Device Testing**: Always test on physical device, not simulator
- **Threading Strict**: Main thread ONLY for UI, background for ALL operations

### Performance Considerations
- Use background queues for Core Data operations
- Implement proper error handling
- Optimize for smooth UI updates
- Follow Apple's native UI/UX conventions

## Development Phases

### Phase 1: Core Data Foundation ✅
- [x] Create project structure and configuration files
- [x] Create Core Data model entities
  - [x] Category entity
  - [x] Entry entity  
  - [x] Group entity
  - [x] Item entity
  - [x] User entity
  - [x] UserGroup entity
- [x] Create ViewModels for each entity
- [x] Update Core Data model file
- [x] Optimize ViewModels for native performance
- [x] Implement background queues for Core Data operations

### Phase 2: Basic UI Structure ✅
- [x] Create main navigation structure with NavigationStack
- [x] Implement basic list views for User entity
- [x] Add/Edit forms for User entity
- [x] Basic CRUD operations in UI for User entity
- [x] **Create Group from User functionality** ✅
  - [x] Add "Create Group" button in User detail view
  - [x] Create Group creation form
  - [x] Link User as owner of the new Group
  - [x] Create UserGroup relationship automatically
- [x] Implement basic list views for other entities
- [x] Add/Edit forms for other entities
- [x] Basic CRUD operations in UI for all entities

### Phase 3: Business Logic
- [ ] Implement expense calculation logic
- [ ] Add category management
- [ ] Group sharing functionality
- [ ] User authentication flow

### Phase 4: Advanced Features
- [ ] Charts and analytics
- [ ] Export functionality
- [ ] Notifications and reminders
- [ ] Data backup and sync

### Phase 5: Polish & Testing
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] App Store preparation

## Current Focus
✅ **COMPLETED**: Phase 2 - Basic UI Structure. All core UI components implemented with MVVM architecture.

**NEXT**: Phase 3 - Business Logic implementation.

## Completed Work

### Core Data Entities ✅
1. **Category** ✅ - Expense categories with color coding and group relationships
2. **Entry** ✅ - Main expense entries with dates, descriptions, and relationships
3. **Group** ✅ - Expense groups for sharing between users with currency support
4. **Item** ✅ - Individual items within expense entries with amounts and quantities
5. **User** ✅ - App users with authentication and group membership
6. **UserGroup** ✅ - Junction table for user-group relationships with role management

### ViewModels ✅
1. **CategoryViewModel** ✅ - Full CRUD operations with filtering and validation
2. **EntryViewModel** ✅ - Full CRUD operations with date filtering and total calculations
3. **GroupViewModel** ✅ - Full CRUD operations with member counting and sorting
4. **ItemViewModel** ✅ - Full CRUD operations with amount calculations and filtering
5. **UserViewModel** ✅ - Full CRUD operations with email validation and role checking
6. **UserGroupViewModel** ✅ - Full CRUD operations with role validation and permissions

### UI Components ✅
1. **MainView** ✅ - Root navigation with NavigationStack
2. **UserListView** ✅ - List of users with add/edit/delete functionality
3. **UserRowView** ✅ - Individual user row component
4. **AddUserView** ✅ - Form to create new users
5. **EditUserView** ✅ - Form to edit existing users
6. **CreateGroupView** ✅ - Form to create new groups with user ownership

### Architecture Features ✅
- **MVVM Compliance**: All business logic in ViewModels, Views only display
- **Core Data Best Practices**: Proper delete rules, relationship management
- **Error Handling**: Comprehensive error handling with user feedback
- **Data Validation**: Input validation for emails, roles, and business rules
- **Performance**: Efficient filtering, sorting, and calculation methods
- **Native Performance**: Background queues for Core Data operations
- **UI Thread Safety**: @MainActor for all ViewModels
- **Background Threading**: All CRUD operations use context.perform for non-blocking UI
- **Async Operations**: Proper async/await support for complex operations
- **Debug Tools**: Comprehensive debugging system for data persistence verification

## Next Steps
1. **Business Logic Implementation** - Start Phase 3 development
2. **Expense Calculation Logic** - Implement expense calculation and reporting
3. **Category Management UI** - Implement Category entity UI with color coding
4. **Entry Management UI** - Implement Entry entity UI with date filtering
5. **Item Management UI** - Implement Item entity UI with amount calculations
6. **Group Sharing Functionality** - Implement user invitation and role management

## Commit History
- ✅ **Commit 1**: Category entity and ViewModel
- ✅ **Commit 2**: Entry entity and ViewModel  
- ✅ **Commit 3**: Group entity and ViewModel
- ✅ **Commit 4**: Item entity and ViewModel
- ✅ **Commit 5**: User entity and ViewModel
- ✅ **Commit 6**: UserGroup entity and ViewModel
- ✅ **Commit 7**: Complete MVVM architecture with native performance optimizations
- ✅ **Commit 8**: Background threading implementation for Core Data operations
- ✅ **Commit 9**: Enhanced debug functionality for data persistence verification
- ✅ **Commit 10**: CreateGroupView and Extensions with MVVM architecture
- ✅ **Commit 11**: Complete MVVM architecture implementation with proper threading

## Technical Notes
- **iOS Target**: iOS 18.5+ (2025) - Usar APIs más modernas disponibles
- All entities implement `Identifiable` protocol for SwiftUI compatibility
- ViewModels use `@MainActor` for UI thread safety
- **All ViewModels now use background queues for Core Data operations** ✅
- Proper Core Data delete rules implemented (Cascade, Nullify)
- Comprehensive computed properties for formatted display
- Utility methods for common operations and filtering
- NavigationStack implementation for modern iOS navigation
- Strict MVVM architecture with no business logic in Views
- **Background threading prevents UI blocking during data operations** ✅
- **Async operations support for complex workflows** ✅
- **Debug system for comprehensive data persistence verification** ✅
- **Extensions for safe operations and utility functions** ✅
- **Modern SwiftUI APIs**: onChange con nueva sintaxis, @Observable macro

## Threading Implementation ✅
- **Main Thread**: Reserved exclusively for UI updates and user interactions
- **Background Threads**: All Core Data operations use `context.perform`
- **Thread Safety**: Proper use of `@MainActor` and `Task` for UI updates
- **Performance**: No UI blocking during database operations
- **Consistency**: All ViewModels follow the same threading pattern
- **Error Handling**: Proper error propagation from background to main thread

## 🚨 RECORDATORIOS CRÍTICOS - REVISAR ANTES DE CADA COMMIT

### ✅ VERIFICAR ANTES DE COMMIT:
1. **Views**: ¿Solo contienen SwiftUI Views sin lógica?
2. **ViewModels**: ¿Solo contienen lógica de negocio sin UI?
3. **Threading**: ¿Operaciones pesadas en background, UI en main?
4. **@Published**: ¿Se usa para reactividad automática?
5. **@MainActor**: ¿Se usa en ViewModels para operaciones de UI?
6. **Delays**: ¿NO hay Timers o delays artificiales?
7. **iOS 18.5+**: ¿Se usan APIs modernas, no deprecadas?
8. **onChange**: ¿Se usa nueva sintaxis `{ oldValue, newValue in }`?

### ❌ ERRORES CRÍTICOS - NO COMMIT:
- Lógica de negocio en Views
- UI elements en ViewModels
- Operaciones pesadas en main thread
- Timers para delays artificiales
- Task.sleep para esperas
- Callbacks manuales innecesarios
- APIs deprecadas de iOS (onChange antiguo, etc.)
- Sintaxis obsoleta de SwiftUI

### 🎯 OBJETIVO FINAL
**UI completamente fluida, sin bloqueos, con operaciones pesadas ejecutándose en background y actualizaciones automáticas en main thread usando la reactividad automática de SwiftUI.**

---

**RECUERDA: Cada línea de código debe seguir estas reglas estrictas. La arquitectura MVVM y el threading correcto son OBLIGATORIOS para mantener la fluidez de la UI.**
