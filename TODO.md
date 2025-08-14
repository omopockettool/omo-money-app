# OMOMoney - SwiftUI Expense Tracker App Development TODO

## 🚨 REGLAS ESTRICTAS DE DESARROLLO - OBLIGATORIAS

### 📱 VERSIÓN DE PLATAFORMA - OBLIGATORIO
- **iOS Target**: iOS 18.5+ (2025)
- **SwiftUI**: Usar APIs más modernas disponibles
- **Compatibilidad**: No usar APIs deprecadas

### 🏗️ ARQUITECTURA MVVM - NO NEGOCIABLE
- **Views**: ❌ NO contienen lógica, ❌ NO cálculos, ❌ NO formateo, ✅ SOLO SwiftUI Views
- **ViewModels**: ❌ NO contienen UI, ✅ SOLO lógica de presentación, ✅ @MainActor, ✅ @Published
- **Services**: ✅ SOLO lógica CRUD y operaciones de datos, ✅ NO lógica de presentación
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

## 🆕 NUEVAS REGLAS MVVM APRENDIDAS HOY - OBLIGATORIAS

### 🔄 GESTIÓN DEL CICLO DE VIDA DEL VIEWMODEL
- **ViewModel Protocol**: ✅ Debe conformar `ObservableObject`
- **@StateObject en Views**: ✅ Usar `@StateObject` cuando la vista crea y posee el ViewModel
- **Beneficio**: Evita reinicialización del ViewModel en cada redibujo, previene pérdida de estado
- **Ejemplo**: `@StateObject private var viewModel = UserListViewModel()`

### 💉 INYECCIÓN DE DEPENDENCIAS EN VIEWMODEL
- **Service Injection**: ✅ ViewModel debe recibir service como parámetro de inicialización
- **Principio**: Dependency Injection para aislar lógica de persistencia/red
- **Beneficio**: Facilita mocking en tests unitarios y separación de responsabilidades
- **Ejemplo**:
```swift
init(service: UserServiceProtocol) {
    self.service = service
}
```

### 📁 ESTRUCTURA DEL PROYECTO
- **Directorio Base**: ✅ Mantener para componentes reusables (ej. Loading)
- **Ruta sugerida**: `Base/View/Loading/Loading.swift`
- **Organización**: Separar claramente Views, ViewModels, Services, Models

### ⚡ CONCURRENCIA Y ASINCRONÍA
- **Swift Concurrency**: ✅ Usar `async/await` en lugar de callbacks anidados o Combine
- **Beneficios**:
  - Código más limpio y legible
  - Manejo integrado de errores con `try/catch`
  - Evita errores de concurrencia al actualizar UI
- **@MainActor**: ✅ Usar cuando sea necesario para operaciones de UI

### 🎯 RESUMEN DE ROLES
- **ViewModel**: `ObservableObject` que expone datos y lógica a la vista
- **Service**: Encapsula acceso a datos (API, Core Data, etc.) y se inyecta en ViewModel
- **View**: Usa `@StateObject` para instanciar ViewModel y reaccionar a cambios

### 🚀 OPTIMIZACIONES DE FLUIDEZ - DIFERENCIADORAS
- **@MainActor**: ✅ Usar correctamente en propiedades que actualizan UI
- **Lazy Loading**: ✅ Usar `LazyVStack`, `List` para vistas grandes
- **Procesamiento Pesado**: ❌ NO en cuerpo de vista, ✅ TODO en ViewModel o Services
- **Caching**: ✅ Cachear datos cuando tenga sentido (imágenes, resultados Core Data)
- **Animaciones**: ✅ Usar `withAnimation` y transiciones nativas SwiftUI

## Project Overview
Building a native iOS personal expense tracker app using SwiftUI (iOS 18.5+) with STRICT MVVM architecture, Core Data persistence, and NavigationStack navigation building into the view model for simplicity.

## Development Strategy
- **Incremental Development**: Small, focused commits for each feature
- **MVVM First**: All business logic in ViewModels, Views only display
- **Core Data Foundation**: Start with data model, build UI on top
- **Test-Driven**: Unit tests for each component
- **Physical Device Testing**: Always test on physical device, not simulator
- **Threading Strict**: Main thread ONLY for UI, background for ALL operations
- **Dependency Injection**: Services injected into ViewModels for testability
- **Lifecycle Management**: Proper @StateObject usage for ViewModel persistence

### Performance Considerations
- Use background queues for Core Data operations
- Implement proper error handling
- Optimize for smooth UI updates
- Follow Apple's native UI/UX conventions
- Use lazy loading for large lists and views
- Cache frequently accessed data
- Implement smooth animations and transitions

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

### Phase 2.5: Architecture Reorganization ✅
- [x] **REORGANIZACIÓN COMPLETA DE ARQUITECTURA MVVM** - Mejorar estructura del proyecto ✅
  - [x] Crear nueva estructura de directorios siguiendo mejores prácticas MVVM ✅
  - [x] Implementar capa Services para separar lógica CRUD de ViewModels ✅
  - [x] Reorganizar ViewModels por funcionalidad (User/, Group/, Entry/) ✅
  - [x] Reorganizar Views por funcionalidad (User/, Group/, Entry/) ✅
  - [x] Crear Utilities/ para extensiones y helpers ✅
  - [x] Crear Base/ para componentes reusables (Loading, etc.) ✅
  - [x] Reorganizar CoreDataStack/ para mejor gestión de persistencia ✅
  - [x] Actualizar todos los imports y referencias ✅
  - [x] Verificar que se mantenga threading correcto (context.perform) ✅
  - [x] Verificar que se mantenga arquitectura MVVM estricta ✅
  - [x] **IMPLEMENTAR INYECCIÓN DE DEPENDENCIAS** - Services inyectados en ViewModels ✅
  - [x] **IMPLEMENTAR @StateObject** - Gestión correcta del ciclo de vida del ViewModel ✅
  - [x] **IMPLEMENTAR LAZY LOADING** - Para listas y vistas grandes ✅
  - [x] **IMPLEMENTAR CACHING** - Para datos frecuentemente accedidos ✅
  - [x] **IMPLEMENTAR ANIMACIONES SUAVES** - Con withAnimation y transiciones nativas ✅
  - [x] Testing de funcionalidad después de reorganización ✅

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
✅ **COMPLETED**: Phase 2.5 - Complete MVVM Architecture Reorganization with new best practices.

**NEXT**: Phase 3 - Business Logic Implementation with enhanced architecture.

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
1. ✅ **Complete MVVM Architecture Reorganization** - Implement new best practices learned today ✅
2. ✅ **Dependency Injection Implementation** - Inject services into ViewModels ✅
3. ✅ **@StateObject Implementation** - Proper ViewModel lifecycle management ✅
4. ✅ **Performance Optimizations** - Lazy loading, caching, smooth animations ✅
5. 🔧 **Corregir CoreDataService Architecture** - Eliminar herencia ObservableObject
6. 🔄 **Refactorizar Validación Asíncrona** - Corregir EditUserViewModel
7. 📱 **Implementar Lazy Loading Avanzado** - LazyVStack y paginación
8. 💾 **Sistema de Caching Inteligente** - Cache de datos y validaciones
9. ✨ **Sistema de Animaciones Suaves** - withAnimation y transiciones
10. **Business Logic Implementation** - Start Phase 3 development
11. **Expense Calculation Logic** - Implement expense calculation and reporting

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
- 🔧 **Commit 12**: Corregir CoreDataService Architecture - Eliminar herencia ObservableObject
- 🔄 **Commit 13**: Refactorizar Validación Asíncrona - Corregir EditUserViewModel
- 📱 **Commit 14**: Implementar Lazy Loading Avanzado - LazyVStack y paginación
- 💾 **Commit 15**: Sistema de Caching Inteligente - Cache de datos y validaciones
- ✨ **Commit 16**: Sistema de Animaciones Suaves - withAnimation y transiciones

## Technical Notes
- **iOS Target**: iOS 18.5+ (2025) - Usar APIs más modernas disponibles
- **Core Data Entities**: Generated automatically with "Codegen: Class Definition" ✅
- All entities implement `Identifiable` protocol for SwiftUI compatibility
- ViewModels use `@MainActor` for UI thread safety
- **All ViewModels now use background queues for Core Data operations** ✅
- **Service Layer**: Complete protocol-based service architecture implemented ✅
- **Dependency Injection**: All ViewModels receive services as parameters ✅
- **@StateObject**: Proper ViewModel lifecycle management in Views ✅
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
- **Base Components**: Reusable LoadingView components for consistent UI ✅
- **Service Protocols**: All services conform to protocols for testability ✅

## Threading Implementation ✅
- **Main Thread**: Reserved exclusively for UI updates and user interactions
- **Background Threads**: All Core Data operations use `context.perform`
- **Thread Safety**: Proper use of `@MainActor` and `Task` for UI updates
- **Performance**: No UI blocking during database operations
- **Consistency**: All ViewModels follow the same threading pattern
- **Error Handling**: Proper error propagation from background to main thread

## 🆕 NUEVAS IMPLEMENTACIONES REQUERIDAS

### 🔄 ViewModel Lifecycle Management ✅
- [x] **@StateObject Implementation**: Cambiar todos los ViewModels a @StateObject en Views ✅
- [x] **ObservableObject Protocol**: Verificar que todos los ViewModels conformen ObservableObject ✅
- [x] **Lifecycle Testing**: Verificar que ViewModels no se reinicialicen en redibujos ✅

### 💉 Dependency Injection ✅
- [x] **Service Injection**: Modificar todos los ViewModels para recibir services como parámetros ✅
- [x] **Protocol Creation**: Crear protocols para todos los services (UserServiceProtocol, etc.) ✅
- [x] **Initialization Update**: Actualizar todas las instanciaciones de ViewModels ✅
- [x] **Testing Preparation**: Preparar estructura para tests unitarios con mocking ✅

### 📁 Project Structure Enhancement ✅
- [x] **Base Directory**: Crear directorio Base/ para componentes reusables ✅
- [x] **Loading Component**: Implementar Loading.swift en Base/View/Loading/ ✅
- [x] **Directory Reorganization**: Reorganizar Views, ViewModels, Services por funcionalidad ✅
- [x] **Import Cleanup**: Limpiar y organizar todos los imports ✅
- [x] **Services Organization**: Organizar Services en Protocols/ e Implementation/ ✅
- [x] **Remove Unnecessary Files**: Eliminar ServiceImports.swift innecesario ✅

### ⚡ Concurrency & Performance
- [x] **Async/Await Migration**: Migrar callbacks a async/await donde sea posible ✅
- [x] **Lazy Loading**: Implementar LazyVStack y List para vistas grandes ✅
- [x] **Caching Strategy**: Implementar sistema de cache para datos frecuentes ✅
- [x] **Animation System**: Implementar withAnimation y transiciones suaves ✅
- [x] **@MainActor Optimization**: Optimizar uso de @MainActor en propiedades de UI ✅

## 🚀 PRÓXIMOS PASOS REQUERIDOS - IMPLEMENTACIÓN INMEDIATA

### 1. **Corregir CoreDataService Architecture** 🔧
- [ ] **Eliminar herencia ObservableObject**: Los Services NO deben ser ObservableObject
- [ ] **Mantener funcionalidad**: Preservar todos los métodos async/await
- [ ] **Testing**: Verificar que la funcionalidad se mantiene intacta

### 2. **Refactorizar Validación Asíncrona** 🔄
- [ ] **Corregir EditUserViewModel**: Mover Task anidado a método separado
- [ ] **Implementar validateNameAsync()**: Método async para validación de nombres
- [ ] **Eliminar MainActor.run innecesario**: Ya estamos en @MainActor

### 3. **Implementar Lazy Loading Avanzado** 📱
- [ ] **LazyVStack en listas grandes**: Para UserListView y otras listas
- [ ] **Lazy loading de imágenes**: Si se implementan en el futuro
- [ ] **Pagination**: Para listas muy grandes (opcional)

### 4. **Sistema de Caching Inteligente** 💾
- [ ] **Cache de datos Core Data**: Para operaciones frecuentes
- [ ] **Cache de validaciones**: Para evitar re-validaciones innecesarias
- [ ] **Cache de cálculos**: Para operaciones costosas

### 5. **Sistema de Animaciones Suaves** ✨
- [ ] **withAnimation en transiciones**: Para navegación y cambios de estado
- **Transiciones personalizadas**: Para mejor UX
- **Animaciones de carga**: Para operaciones async

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
9. **@StateObject**: ¿Se usa para ViewModels que la vista posee?
10. **Dependency Injection**: ¿Los ViewModels reciben services como parámetros?
11. **ObservableObject**: ¿Todos los ViewModels conforman el protocolo?
12. **Lazy Loading**: ¿Se usa para listas y vistas grandes?
13. **Caching**: ¿Se implementa para datos frecuentemente accedidos?
14. **Animations**: ¿Se usan withAnimation y transiciones nativas?

### ❌ ERRORES CRÍTICOS - NO COMMIT:
- Lógica de negocio en Views
- UI elements en ViewModels
- Operaciones pesadas en main thread
- Timers para delays artificiales
- Task.sleep para esperas
- Callbacks manuales innecesarios
- APIs deprecadas de iOS (onChange antiguo, etc.)
- Sintaxis obsoleta de SwiftUI
- ViewModels sin Dependency Injection
- Views sin @StateObject para ViewModels propios
- ViewModels sin protocolo ObservableObject
- Falta de lazy loading en listas grandes
- Falta de caching para datos frecuentes
- Falta de animaciones suaves

### 🎯 OBJETIVO FINAL
**UI completamente fluida, sin bloqueos, con operaciones pesadas ejecutándose en background y actualizaciones automáticas en main thread usando la reactividad automática de SwiftUI, implementando las mejores prácticas MVVM aprendidas hoy.**

---

**RECUERDA: Cada línea de código debe seguir estas reglas estrictas. La arquitectura MVVM, el threading correcto, la inyección de dependencias, y la gestión del ciclo de vida del ViewModel son OBLIGATORIOS para mantener la fluidez de la UI y la mantenibilidad del código.**

## 🚀 **PRÓXIMOS PASOS RECOMENDADOS - IMPLEMENTACIÓN INMEDIATA**

### ✅ **COMPLETADO EN ESTA ITERACIÓN**
- [x] **Corregir CoreDataService Architecture** - Eliminar herencia ObservableObject ✅
- [x] **Refactorizar Validación Asíncrona** - Corregir EditUserViewModel ✅
- [x] **Implementar Lazy Loading Avanzado** - LazyVStack y paginación ✅
- [x] **Sistema de Caching Inteligente** - CacheManager para datos y validaciones ✅
- [x] **Sistema de Animaciones Suaves** - AnimationHelper y transiciones ✅

### 🔧 **PRÓXIMOS PASOS INMEDIATOS**

#### 1. **Implementar Cache en Otros Servicios** 💾
- [ ] **CategoryService**: Agregar cache para categorías y validaciones
- [ ] **ItemService**: Agregar cache para items y cálculos de montos
- [ ] **UserGroupService**: Agregar cache para relaciones usuario-grupo
- [ ] **Cache Invalidation**: Implementar invalidación automática en todos los servicios
- [ ] **Cache Statistics**: Agregar métricas de performance del cache

#### 2. **Testing Unitario con Nueva Arquitectura** 🧪
- [ ] **Service Tests**: Tests unitarios para todos los servicios con mocking
- [ ] **ViewModel Tests**: Tests para ViewModels con servicios inyectados
- [ ] **Cache Tests**: Tests para verificar funcionamiento del sistema de cache
- [ ] **Performance Tests**: Tests de performance para operaciones con cache
- [ ] **Integration Tests**: Tests de integración entre capas

#### 3. **Performance Monitoring y Optimización** 📊
- [ ] **Cache Hit Rate**: Monitorear tasa de aciertos del cache
- [ ] **Memory Usage**: Optimizar uso de memoria del cache
- [ ] **Background Operations**: Monitorear performance de operaciones async
- [ ] **UI Responsiveness**: Medir tiempo de respuesta de la UI
- [ ] **Core Data Performance**: Optimizar queries y operaciones de base de datos

#### 4. **Business Logic Implementation - Phase 3** 🏗️
- [ ] **Expense Calculation Engine**: Motor de cálculos de gastos
- [ ] **Category Management**: Sistema completo de gestión de categorías
- [ ] **Group Sharing Logic**: Lógica de compartir gastos entre usuarios
- [ ] **Currency Conversion**: Sistema de conversión de monedas
- [ ] **Budget Management**: Gestión de presupuestos por grupo

#### 5. **Advanced Features Implementation** 🚀
- [ ] **Real-time Updates**: Actualizaciones en tiempo real entre usuarios
- [ ] **Offline Support**: Sincronización offline con Core Data
- [ ] **Data Export**: Exportación de datos en múltiples formatos
- [ ] **Push Notifications**: Notificaciones para recordatorios y actualizaciones
- [ ] **Analytics Dashboard**: Dashboard de análisis de gastos

### 📈 **MÉTRICAS DE PERFORMANCE OBJETIVO**
- **Cache Hit Rate**: >80% para operaciones frecuentes
- **UI Response Time**: <100ms para operaciones de usuario
- **Background Operations**: <500ms para operaciones Core Data
- **Memory Usage**: <50MB para cache en uso activo
- **App Launch Time**: <2 segundos para carga inicial

### 🎯 **CRITERIOS DE ÉXITO**
- [ ] **Performance**: UI completamente fluida sin bloqueos
- [ ] **Scalability**: App maneja 1000+ usuarios sin degradación
- [ ] **Reliability**: 99.9% uptime para operaciones críticas
- [ ] **User Experience**: Transiciones suaves y feedback inmediato
- [ ] **Code Quality**: 100% cobertura de tests y 0 warnings

### 🔄 **ITERACIONES PLANIFICADAS**

#### **Iteración 1 (Siguiente Sprint)**
- Implementar cache en CategoryService e ItemService
- Crear tests unitarios básicos para servicios
- Implementar métricas básicas de performance

#### **Iteración 2 (Sprint +2)**
- Implementar cache en UserGroupService
- Crear tests unitarios para ViewModels
- Implementar sistema de métricas avanzado

#### **Iteración 3 (Sprint +3)**
- Implementar motor de cálculos de gastos
- Crear tests de integración
- Optimizar performance basado en métricas

#### **Iteración 4 (Sprint +4)**
- Implementar features avanzadas
- Tests de performance y stress
- Preparación para producción

---

**ESTADO ACTUAL: ✅ FASE 2.5 COMPLETADA - Arquitectura MVVM sólida con Swift Concurrency optimizado**

**PRÓXIMO OBJETIVO: 🚀 IMPLEMENTAR CACHE COMPLETO EN TODOS LOS SERVICIOS + TESTING UNITARIO**
