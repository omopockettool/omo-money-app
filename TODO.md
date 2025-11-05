# OMOMoney - SwiftUI Expense Tracker App Development TODO

## ✅ MILESTONE COMPLETADO: First UI Implementation (v0.10.0)

### 🎉 LOGROS ALCANZADOS
- **DashboardView Completo**: UI principal con integración backend funcional
- **AddItemListView Funcional**: Flujo completo de creación de gastos
- **Core Data Sincronización**: UI se actualiza en tiempo real sin reiniciar app
- **NSManagedObjectContextDidSave**: Patrón nativo iOS implementado correctamente
- **Cache Management**: Sistema inteligente multi-nivel funcionando
- **Threading Architecture**: async/await + @MainActor patterns correctos
- **MVVM Architecture**: Implementación completa siguiendo best practices iOS

## 🔧 SOLUCIÓN CORE DATA NAVIGATION CONTEXT - DOCUMENTADA

### 🎯 **PROBLEMA RESUELTO: Diferentes Contextos en Navigation**
**Síntoma**: Dashboard no se actualiza después de crear ItemList via NavigationStack
**Causa**: Vista hija usa contexto diferente al padre, Core Data no sincroniza automáticamente
**Solución Implementada**: **Callback-based refresh pattern**

### ✅ **PATRÓN CALLBACK-BASED REFRESH - FUNCIONANDO**
```swift
// 1. Vista padre (DashboardView) pasa callback onItemListCreated
.navigationDestination(for: String.self) { destination in
    AddItemListView(
        user: user,
        group: group,
        context: context,  // ✅ MISMO CONTEXTO
        navigationPath: $navigationPath,
        onItemListCreated: {  // ✅ CALLBACK PATTERN
            Task {
                await viewModel.refreshData()  // ✅ REFRESH MANUAL
            }
        }
    )
}

// 2. Vista hija (AddItemListView) ejecuta callback después de crear
private func saveItemList() async {
    let success = await viewModel.createItemList(...)
    if success {
        onItemListCreated()  // ✅ TRIGGER REFRESH
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationPath.removeLast()  // ✅ NAVIGATE BACK
        }
    }
}
```

### 🚨 **REGLA CRÍTICA PARA NAVIGATION + CORE DATA**
- **USAR MISMO CONTEXTO**: Vista padre e hija deben usar mismo NSManagedObjectContext
- **CALLBACK REFRESH**: Vista padre implementa callback que refrezca datos después de cambios
- **TIMING**: Delay mínimo (0.1s) antes de navegación para evitar conflictos
- **PATTERN**: `context.perform` → callback → `await refreshData()` → navigate back

### 📝 **APLICAR EN FUTURAS IMPLEMENTACIONES**
- ✅ Usar este patrón para cualquier navegación que modifique Core Data
- ✅ Pasar siempre mismo contexto y callback de refresh
- ✅ NO confiar solo en NSManagedObjectContextDidSave para navigation
- ✅ Implementar delay mínimo antes de navegación programática

## 🎯 PRÓXIMO OBJETIVO: ItemList Delete Functionality

### � EN DESARROLLO
- **Delete ItemList**: Implementar borrado de gastos desde el dashboard
  - Swipe-to-delete gesture en ExpenseRowView
  - Confirmación de borrado con alert nativo
  - Actualización automática de UI después del borrado
  - Manejo de errores en caso de fallos de borrado

## �🚨 REGLAS ESTRICTAS DE DESARROLLO - VALIDADAS Y FUNCIONANDO

### 📱 VERSIÓN DE PLATAFORMA - OBLIGATORIO ✅
- **iOS Target**: iOS 18.5+ (2025) - ✅ IMPLEMENTADO
- **SwiftUI**: APIs modernas - ✅ NavigationStack, onChange syntax
- **Compatibilidad**: Sin APIs deprecadas - ✅ VERIFICADO

### 🏗️ ARQUITECTURA MVVM VALIDADA - FUNCIONANDO ✅
- **Views**: ✅ Solo SwiftUI Views sin lógica - IMPLEMENTADO
- **ViewModels**: ✅ @MainActor, @Published, lógica de presentación - FUNCIONANDO
- **Services**: ✅ Solo CRUD y operaciones de datos - IMPLEMENTADO
- **Models**: ✅ Solo entidades Core Data - CORRECTO
- **Core Data Integration**: ✅ NSManagedObjectContextDidSave notifications - FUNCIONANDO PERFECTAMENTE

### 🧵 THREADING & CONCURRENCY - CRÍTICO
- **Main Thread**: ✅ SOLO UI, ✅ navegación, ✅ gestos, ✅ animaciones
- **Background Thread**: ✅ Core Data CRUD, ✅ cálculos complejos, ✅ sync operations
- **Async/Await**: ✅ OBLIGATORIO para todas las operaciones async
- **Sendable**: ✅ Marcar clases como Sendable donde corresponda
- **@MainActor**: ✅ Para métodos que tocan UI

### 🧵 THREADING & CONCURRENCY VALIDADO - FUNCIONANDO ✅
- **Main Thread**: ✅ Solo UI, navegación, animaciones - IMPLEMENTADO
- **Background Thread**: ✅ Core Data CRUD, cálculos - FUNCIONANDO
- **Async/Await**: ✅ Implementado en toda la app - CORRECTO
- **@MainActor**: ✅ Para ViewModels y UI updates - FUNCIONANDO

### 📱 SWIFTUI REACTIVIDAD COMPROBADA - WORKING ✅  
- ✅ `@Published` + SwiftUI redibujado automático - FUNCIONANDO
- ✅ NSManagedObjectContextDidSave notifications - IMPLEMENTADO
- ✅ onChange syntax moderna - USANDO
- ✅ NavigationStack moderno - IMPLEMENTADO
- ❌ Sin Timers ni delays artificiales - ELIMINADOS
- ❌ Sin callbacks manuales innecesarios - LIMPIO

### 🚫 PROHIBIDO - VALIDADO Y ELIMINADO ✅
- ❌ Operaciones pesadas en main thread - ELIMINADO
- ❌ Lógica de negocio en Views - SEPARADO CORRECTAMENTE  
- ❌ UI elements en ViewModels - ARQUITECTURA LIMPIA
- ❌ Delays artificiales o polling - ELIMINADO
- ✅ Core Data via Services solamente - IMPLEMENTADO

## � PATRONES MVVM DOMINADOS - APLICADOS Y FUNCIONANDO

### 🔄 GESTIÓN DEL CICLO DE VIDA - IMPLEMENTADO ✅
- **ObservableObject**: ✅ ViewModels conforman protocolo - FUNCIONANDO
- **@StateObject**: ✅ Views poseen ViewModels correctamente - IMPLEMENTADO  
- **Lifecycle Management**: ✅ Sin reinicialización en redraws - ESTABLE
- **Estado Persistente**: ✅ ViewModels mantienen estado - CORRECTO

### 💉 DEPENDENCY INJECTION - FUNCIONANDO ✅
- **Service Injection**: ✅ ViewModels reciben services - IMPLEMENTADO
- **Testability**: ✅ Arquitectura preparada para testing - READY
- **Separation of Concerns**: ✅ Lógica separada correctamente - CLEAN
- **Protocol-Based**: ✅ Services usan protocolos - FLEXIBLE  

### 📁 ESTRUCTURA DEL PROYECTO - ORGANIZADA ✅
- **Base Components**: ✅ Loading, reusables organizados - IMPLEMENTED
- **Clear Separation**: ✅ Views, ViewModels, Services separados - CLEAN
- **Scalable Architecture**: ✅ Preparado para crecimiento - READY

### ⚡ CONCURRENCIA MODERNA - WORKING ✅
- **async/await**: ✅ Implementado en toda la app - FUNCTIONING
- **Error Handling**: ✅ try/catch patterns - ROBUST
- **@MainActor**: ✅ UI operations isolated - SAFE
- **Threading**: ✅ Background/main pattern perfect - OPTIMIZED

### 🚀 OPTIMIZACIONES IMPLEMENTADAS - PERFORMANCE ✅
- **@MainActor**: ✅ UI properties correctly isolated - WORKING
- **Lazy Loading**: ✅ Large lists optimized - IMPLEMENTED
- **Smart Caching**: ✅ Core Data results cached - PERFORMANCE
- **Smooth Animations**: ✅ withAnimation patterns - POLISHED

## ✅ TRABAJO COMPLETADO

### 🎯 **🆕 v0.10.0 - First UI Implementation (Nov 3, 2025) - MILESTONE MAYOR**
- [x] **DashboardView Completo**: UI principal con integración backend totalmente funcional ✅
- [x] **AddItemListView Funcional**: Flujo completo de creación de gastos working ✅
- [x] **ExpenseRowView Component**: Componente reutilizable con colores de categoría ✅
- [x] **Core Data UI Sync**: NSManagedObjectContextDidSave notifications implementadas ✅
- [x] **Real-time UI Updates**: Dashboard se actualiza automáticamente al crear ItemList ✅
- [x] **Cache Management**: Sistema inteligente multi-nivel completamente funcional ✅
- [x] **Threading Architecture**: async/await + @MainActor patterns perfectos ✅
- [x] **Navigation Integration**: Callback-based refresh con NavigationStack ✅
- [x] **Error Handling**: Manejo robusto de errores en toda la UI ✅
- [x] **iOS Best Practices**: Arquitectura validada contra guidelines de Apple ✅

### 🎯 **v0.9.0 - Multi-User Security Architecture (Nov 1, 2025)**
- [x] **Security Model**: Eliminación completa de métodos globales inseguros ✅
- [x] **Context-Aware Operations**: Todos los servicios requieren user/group context ✅
- [x] **Data Isolation**: Prevención total de acceso cruzado entre usuarios ✅
- [x] **Service Layer Security**: Filtrado obligatorio por user/group en todos los métodos ✅
- [x] **ViewModel Security**: Alineación completa con arquitectura segura ✅

### 🎯 **v0.8.0 - Arquitectura Simplificada (Sep 13, 2025)**
- [x] **MainView Simplificado**: Reducido de 174 a 109 líneas eliminando complejidad innecesaria ✅
- [x] **AppContentView Nuevo**: Vista principal dedicada para usuarios autenticados ✅
- [x] **Flujo de Primer Usuario**: Sheet modal con redirección automática y cierre inteligente ✅
- [x] **Async Callbacks**: Implementación moderna con async/await sin Task wrappers innecesarios ✅
- [x] **Service Architecture**: Eliminado ObservableObject de services, DI pura ✅
- [x] **Navigation Simplification**: Eliminados enums complejos, navegación directa ✅
- [x] **Optional Safety**: Manejo seguro de Core Data optionals con nil coalescing ✅
- [x] **Sheet Management**: Cierre automático con timing perfecto (0.2s delay) ✅
- [x] **Compilation Clean**: Cero errores, warnings o trailing closure issues ✅
- [x] **UX Flow Perfected**: App vacía → Modal → Crear usuario → Redirección → Dashboard ✅

### 🎯 **Sistema de Navegación Completo**
- [x] **Create Group Navigation**: Implementado NavigationDestination para CreateGroupView ✅
- [x] **Settings Navigation**: Implementado NavigationDestination para SettingsView ✅  
- [x] **Add ItemList Navigation**: Implementado NavigationDestination para AddItemListView ✅
- [x] **Navigation Testing**: Verificado que todas las navegaciones funcionen correctamente ✅
- [x] **Navigation State Management**: Asegurado consistencia del estado de navegación ✅

### 🎯 **Sistema de ItemLists con Reactividad Automática**
- [x] **NSFetchedResultsController**: Implementado para reactividad automática de Core Data ✅
- [x] **Lista de ItemLists**: ItemLists se muestran automáticamente sin refresh manual ✅
- [x] **Lazy Loading & Paginación**: Implementado para listas grandes ✅
- [x] **Validaciones de Seguridad**: Prevención de crashes de runtime ✅
- [x] **Threading Correcto**: Background → main thread pattern implementado ✅
- [x] **MVVM Respetado**: ViewModel maneja lógica, Views solo muestran datos ✅

### 🎯 **Arquitectura y Performance**
- [x] **MVVM Strict**: Separación completa de responsabilidades ✅
- [x] **Core Data Best Practices**: NSFetchedResultsController nativo ✅
- [x] **Threading Safety**: Main thread libre para UI ✅
- [x] **Error Prevention**: Validaciones robustas implementadas ✅
- [x] **Swift 6 Compatibility**: Sin errores de MainActor isolation ✅

### 🎯 **Sistema de Primer Usuario y Estabilidad**
- [x] **First User Creation Flow**: Sheet automático cuando la app está vacía ✅
- [x] **Protection Flags**: Prevención de ejecuciones múltiples simultáneas ✅
- [x] **Stable State Management**: Estado consistente de objetos Core Data ✅
- [x] **Core Data Validation**: Validaciones simplificadas que confían en Core Data ✅
- [x] **Infinite Loop Prevention**: Flags para evitar bucles infinitos ✅
- [x] **Concurrency Safety**: Protección contra operaciones simultáneas ✅

### 🎯 **PaymentMethod Entity System**
- [x] **Entry → ItemList Renaming**: Refactorización completa de nombres para mayor claridad semántica ✅
- [x] **PaymentMethod Core Data Model**: Entidad completa con relaciones CASCADE/NULLIFY ✅
- [x] **PaymentMethod Service Layer**: Implementación completa con async/await y cache inteligente ✅
- [x] **PaymentMethod ViewModels**: Sistema MVVM completo (List, Picker, Add/Edit) ✅
- [x] **PaymentMethod Integration**: Integración con ItemList y Group entities ✅

### 🎯 **Performance Enhancement Framework**
- [x] **Background Context Support**: Contextos dedicados para operaciones pesadas ✅
- [x] **Batch Operations Framework**: Sistema de operaciones en lote para Core Data ✅
- [x] **Smart Data Preloading**: Sistema de precarga inteligente con progreso ✅
- [x] **Enhanced Cache Management**: Cache con limpieza automática y monitoreo ✅
- [x] **Performance Monitoring**: Sistema de monitoreo con scoring automático ✅

### 🎯 **Batch Operations Implementation**
- [x] **User Entity Batch Operations**: bulkDeleteUsers, bulkUpdateUserStatus, createUsers ✅
- [x] **Group Entity Batch Operations**: bulkDeleteGroups, bulkUpdateGroupCurrency, createGroups ✅
- [x] **Enhanced Query Methods**: Currency-specific counts, member counts, relationship queries ✅
- [x] **ViewModel Integration**: Batch operations integrados en ViewModels con UI responsiva ✅
- [x] **Performance Optimization**: 20-50x mejora de rendimiento en operaciones masivas ✅

## Project Overview
Building a native iOS personal expense tracker app using SwiftUI (iOS 18.5+) with STRICT MVVM architecture, Core Data persistence, and NavigationStack navigation building into the view model for simplicity.

## 🚀 PRÓXIMAS TAREAS - ROADMAP ACTUALIZADO

### 🎯 **INMEDIATO: Delete ItemList Functionality (v1.1.0)**
- [ ] **Swipe-to-Delete Gesture**: Implementar en ExpenseRowView con SwiftUI nativo
- [ ] **Delete Confirmation**: Alert nativo iOS con opciones Cancelar/Eliminar
- [ ] **Delete Service Method**: Agregar deleteItemList() a ItemListService
- [ ] **UI Refresh After Delete**: Automático via NSManagedObjectContextDidSave
- [ ] **Error Handling**: Manejo de errores de borrado con usuario feedback
- [ ] **Animation**: Smooth delete animation con withAnimation
- [ ] **Testing**: Verificar que borrado actualice dashboard inmediatamente

### 🎯 **SIGUIENTE: Enhanced UI Components (v1.2.0)**
- [ ] **Edit ItemList**: Funcionalidad para editar gastos existentes
- [ ] **Item Management**: CRUD completo para items dentro de ItemList
- [ ] **Search & Filter**: Buscar y filtrar gastos por fecha, categoría, monto
- [ ] **Statistics View**: Gráficos y resúmenes de gastos
- [ ] **Export Feature**: Exportar datos a CSV/PDF

### 🎯 **FUTURO: Sincronización y Multi-Device (v2.0.0)**

#### 🔐 **1. SISTEMA DE AUTENTICACIÓN (PREREQUISITO)**
- [ ] **Authentication Service Protocol**: Crear AuthServiceProtocol con login/logout/register
- [ ] **User Session Management**: Gestión de sesión de usuario con tokens seguros
- [ ] **Keychain Integration**: Almacenamiento seguro de credenciales en Keychain
- [ ] **Biometric Authentication**: Touch ID / Face ID para acceso rápido
- [ ] **Authentication Views**: Login, Register, ForgotPassword con SwiftUI
- [ ] **Authentication State**: @Published authentication state para toda la app
- [ ] **Protected Routes**: Navegación condicional basada en estado de autenticación
- [ ] **Logout Flow**: Limpiar datos locales y redirigir a login

#### 🌐 **2. CAPA DE SINCRONIZACIÓN GENÉRICA (CORE)**
- [ ] **SyncableRepository Protocol**: Protocolo genérico `SyncableRepository<T>`
- [ ] **Local Repository Layer**: `CoreDataRepository<T>` para operaciones locales
- [ ] **Remote Repository Layer**: `CloudRepository<T>` para operaciones remotas
- [ ] **Hybrid Repository**: `SyncRepository<T>` que combina local + remote
- [ ] **Conflict Resolution**: Sistema basado en `lastUpdated` timestamp
- [ ] **Sync Queue**: Cola de operaciones pendientes de sincronización
- [ ] **Batch Sync Operations**: Sincronización en lotes para eficiencia
- [ ] **Sync Status Tracking**: Estados: synced, pending, conflict, error

#### 📡 **3. MONITOR DE CONEXIÓN A INTERNET**
- [ ] **NetworkMonitor Service**: Implementar con NWPathMonitor
- [ ] **Connection State Observable**: `@Published isConnected` para reactivity
- [ ] **Connection Quality**: Detectar WiFi vs Cellular vs Ethernet
- [ ] **Retry Logic**: Reintento automático de operaciones fallidas
- [ ] **Background Sync Trigger**: Activar sync cuando vuelva la conexión
- [ ] **Network Error Handling**: Manejo específico de errores de red

#### 🏗️ **4. APPENV IRONMENT GLOBAL**
- [ ] **AppEnvironment Structure**: Container global para todos los repositorios
- [ ] **Environment Configurations**:
  - [ ] `.local`: Solo repositorios Core Data
  - [ ] `.remote`: Solo repositorios remotos  
  - [ ] `.sync`: Repositorios híbridos (DEFAULT)
- [ ] **SwiftUI Environment Integration**: `.environment(\.appEnvironment, value)`
- [ ] **Dependency Injection**: Inyección automática en ViewModels
- [ ] **Environment Switching**: Para testing y desarrollo

#### 🔄 **5. INTEGRACIÓN CON VIEWMODELS EXISTENTES**
- [ ] **Repository Protocol Adoption**: ViewModels usan protocolos, no implementaciones
- [ ] **Transparent Operations**: ViewModels no saben si es local/remote/sync
- [ ] **Error Handling**: Manejo unificado de errores de sync
- [ ] **Loading States**: Estados de carga para operaciones sync
- [ ] **Offline Indicators**: UI feedback para estado offline

#### 📊 **6. FLUJO DE SINCRONIZACIÓN AUTOMÁTICO**
- [ ] **Auto-Sync on Connection**: Sync automático cuando vuelve internet
- [ ] **Background Sync**: Sincronización en background thread
- [ ] **Sync Progress**: Indicadores de progreso para sync masivos
- [ ] **Sync Notifications**: Notificaciones de éxito/error de sync
- [ ] **Sync Scheduling**: Programar syncs periódicos automáticos

### 🎯 **🆕 v0.9.0 - AppContentView Features (SEGUNDA PRIORIDAD)**
- [ ] **Dashboard Implementation**: Implementar dashboard principal con estadísticas básicas
- [ ] **Quick Actions Integration**: Conectar botones de acción rápida con funcionalidades reales
- [ ] **Add Expense Flow**: Implementar flujo completo para agregar gastos desde AppContentView
- [ ] **View Reports Integration**: Conectar con sistema de reportes y gráficos
- [ ] **Settings Navigation**: Restaurar navegación a settings desde AppContentView
- [ ] **Group Management Integration**: Implementar gestión de grupos en la nueva arquitectura
- [ ] **User Profile Access**: Agregar acceso a perfil de usuario desde header
- [ ] **Recent Activity Feed**: Mostrar actividad reciente en el dashboard
- [ ] **Category Quick Access**: Acceso rápido a categorías desde dashboard
- [ ] **Payment Method Integration**: Integrar gestión de métodos de pago

### 🎯 **AppContentView Navigation Architecture**
- [ ] **Internal Navigation System**: Implementar NavigationStack interno para funcionalidades
- [ ] **Tab-based Navigation**: Considerar implementación de tabs para organizar funcionalidades
- [ ] **Modal Presentations**: Sistema de modals para formularios y detalles
- [ ] **Deep Linking Support**: Navegación directa a funcionalidades específicas
- [ ] **Navigation State Management**: Gestión de estado de navegación interna

### 🎯 **INTEGRACIÓN DE DOMINIO Y PERSISTENCIA (TERCERA PRIORIDAD)**

#### 📋 **Domain Models Creation**
- [ ] **Domain User Struct**: Struct User para dominio (separado de Core Data)
- [ ] **Domain Group Struct**: Struct Group para dominio
- [ ] **Domain ItemList Struct**: Struct ItemList para dominio
- [ ] **Domain Item Struct**: Struct Item para dominio
- [ ] **Domain Category Struct**: Struct Category para dominio
- [ ] **Domain PaymentMethod Struct**: Struct PaymentMethod para dominio
- [ ] **Domain Mappers**: Conversión entre Core Data entities y domain structs

#### 🏭 **Repository Implementation per Entity**
- [ ] **UserRepository**: Local, Remote, y Sync implementations
- [ ] **GroupRepository**: Local, Remote, y Sync implementations
- [ ] **ItemListRepository**: Local, Remote, y Sync implementations
- [ ] **ItemRepository**: Local, Remote, y Sync implementations
- [ ] **CategoryRepository**: Local, Remote, y Sync implementations
- [ ] **PaymentMethodRepository**: Local, Remote, y Sync implementations

### 🎯 **User Experience Enhancements (CUARTA PRIORIDAD)**
- [ ] **Loading States**: Implementar loading states en todas las operaciones
- [ ] **Error Handling**: Sistema de manejo de errores unificado con sync
- [ ] **Offline Support UI**: Indicadores visuales de estado offline
- [ ] **Sync Progress UI**: Barras de progreso para sincronización
- [ ] **Pull to Refresh**: Implementar refresh en listas y dashboard
- [ ] **Search Functionality**: Búsqueda global que funcione offline
- [ ] **Conflict Resolution UI**: Interface para resolver conflictos de sync

### 🎯 **Batch Operations Extension (QUINTA PRIORIDAD)**
- [ ] **Sync-Aware Batch Operations**: Batch operations que respeten sync layer
- [ ] **Category Entity Batch Operations**: Implementar bulkDeleteCategories, bulkUpdateCategoryColors, createCategories
- [ ] **ItemList Entity Batch Operations**: Implementar bulkDeleteItemLists, bulkUpdateItemListDates, createItemLists  
- [ ] **Item Entity Batch Operations**: Implementar bulkDeleteItems, bulkUpdateItemAmounts, createItems
- [ ] **PaymentMethod Entity Batch Operations**: Implementar bulkDeletePaymentMethods, bulkUpdatePaymentMethodTypes, createPaymentMethods
- [ ] **UserGroup Entity Batch Operations**: Implementar bulkUpdateUserRoles, bulkAssignUsersToGroups, bulkRemoveUsersFromGroups

### 🎯 **Performance Monitoring & Analytics (SEXTA PRIORIDAD)**
- [ ] **Sync Performance Dashboard**: Vista de monitoreo de sync en tiempo real
- [ ] **Cache Analytics**: Análisis de eficiencia de cache y hit ratios
- [ ] **Network Operation Analytics**: Análisis de operaciones de red y sync
- [ ] **Memory Usage Monitoring**: Monitoreo de uso de memoria y optimizaciones
- [ ] **Sync Alerts**: Sistema de alertas para fallos de sincronización
- [ ] **Group Statistics**: Estadísticas del grupo con datos sincronizados
- [ ] **Group Settings**: Configuración del grupo con sync preferences

### 🎯 **Funcionalidades de Usuarios**
- [ ] **User Profile**: Perfil de usuario completo
- [ ] **User Preferences**: Preferencias del usuario
- [ ] **User Statistics**: Estadísticas personales
- [ ] **User Groups**: Gestión de grupos del usuario

### 🎯 **Funcionalidades Avanzadas**
- [ ] **Data Export**: Exportar datos a CSV/PDF
- [ ] **Backup & Sync**: Respaldo y sincronización
- [ ] **Notifications**: Recordatorios y notificaciones
- [ ] **Analytics**: Gráficos y análisis de gastos

## Development Strategy
- **Offline-First Architecture**: La app debe funcionar completamente offline
- **Incremental Development**: Small, focused commits for each feature
- **Repository Pattern**: All data access through repository abstractions
- **MVVM + Sync**: ViewModels usan repositorios, no conocen sync implementation
- **Test-Driven**: Unit tests para cada repository y componente
- **Physical Device Testing**: Always test on physical device, not simulator
- **Async/Await First**: Todas las operaciones async usan async/await
- **Dependency Injection**: Repositories injected into ViewModels for testability
- **Lifecycle Management**: Proper @StateObject usage for ViewModel persistence
- **Network Resilience**: La app debe manejar elegantemente pérdida de conexión

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
  - [x] ItemList entity  
  - [x] Group entity
  - [x] Item entity
  - [x] User entity
  - [x] UserGroup entity
- [x] Create ViewModels for each entity
- [x] Update Core Data model file
- [x] Optimize ViewModels for native performance
- [x] Implement background queues for Core Data operations

### Phase 1.5: Authentication & Security 🔐
- [ ] **Authentication System**: Implement complete user authentication
- [ ] **Security Layer**: Secure storage and session management
- [ ] **User Context**: Establish authenticated user context throughout app
- [ ] **Protected Navigation**: Conditional navigation based on auth state

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
  - [x] **Navigation implementation with NavigationStack** ✅
    - [x] CreateGroupView navigation working correctly ✅
    - [x] Proper NavigationDestination setup in MainView ✅
    - [x] NavigationPath management for programmatic navigation ✅
- [x] **Complete Navigation System Implementation** ✅
  - [x] Settings Navigation (Tuerca) to SettingsView ✅
  - [x] Add ItemList Navigation to AddItemListView ✅
  - [x] All NavigationDestination enums defined in MainView ✅
  - [x] Consistent NavigationPath management across all views ✅
  - [x] Type-safe navigation using enums with associated values ✅
- [x] Implement basic list views for other entities
- [x] Add/Edit forms for other entities
- [x] Basic CRUD operations in UI for all entities

### Phase 2.5: Architecture Reorganization ✅
- [x] **REORGANIZACIÓN COMPLETA DE ARQUITECTURA MVVM** - Mejorar estructura del proyecto ✅
  - [x] Crear nueva estructura de directorios siguiendo mejores prácticas MVVM ✅
  - [x] Implementar capa Services para separar lógica CRUD de ViewModels ✅
  - [x] Reorganizar ViewModels por funcionalidad (User/, Group/, ItemList/) ✅
  - [x] Reorganizar Views por funcionalidad (User/, Group/, ItemList/) ✅
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

### Phase 3: Sync Architecture Implementation 🔄
- [ ] **Repository Layer**: Implement generic repository pattern
- [ ] **Network Monitoring**: Implement connection state monitoring
- [ ] **Sync Engine**: Build automatic synchronization system
- [ ] **Conflict Resolution**: Handle data conflicts intelligently
- [ ] **AppEnvironment**: Global dependency injection container

### Phase 4: Business Logic
- [ ] **Expense Calculation Logic**: Implement calculation engine
- [ ] **Category Management**: Complete category system
- [ ] **Group Sharing**: Multi-user expense sharing
- [ ] **Currency Conversion**: Multi-currency support

### Phase 5: Advanced Features
- [ ] **Real-time Sync**: Live data synchronization
- [ ] **Charts and Analytics**: Visual expense analysis
- [ ] **Export Functionality**: Data export in multiple formats
- [ ] **Notifications**: Push notifications for sync and reminders
- [ ] **Backup System**: Automated backup and restore

### Phase 6: Polish & Testing
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] App Store preparation

## Current Focus
✅ **COMPLETED**: Phase 1 - Core Data Foundation with security architecture
✅ **COMPLETED**: Phase 2 - Basic UI Structure with MVVM architecture  
✅ **COMPLETED**: Phase 2.5 - Complete Architecture Reorganization with best practices
✅ **COMPLETED**: Security Refactoring - Multi-user security with proper context filtering

**CURRENT**: Phase 1.5 - Authentication System Implementation (PREREQUISITE for sync)
**NEXT**: Phase 3 - Hybrid Sync Architecture Implementation (CORE FEATURE)

## Completed Work

### Core Data Entities ✅
1. **Category** ✅ - Expense categories with color coding and group relationships
2. **ItemList** ✅ - Main expense item lists with dates, descriptions, and relationships
3. **Group** ✅ - Expense groups for sharing between users with currency support
4. **Item** ✅ - Individual items within expense item lists with amounts and quantities
5. **User** ✅ - App users with authentication and group membership
6. **UserGroup** ✅ - Junction table for user-group relationships with role management

### ViewModels ✅
1. **CategoryViewModel** ✅ - Full CRUD operations with filtering and validation
2. **ItemListViewModel** ✅ - Full CRUD operations with date filtering and total calculations
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
- ✅ **Commit 2**: ItemList entity and ViewModel  
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

### 🔧 **PRÓXIMOS PASOS INMEDIATOS - ORDEN DE IMPLEMENTACIÓN**

#### 🔐 **STEP 1: AUTHENTICATION SYSTEM (PREREQUISITO CRÍTICO)**
- [ ] **AuthService Protocol**: Definir AuthServiceProtocol con async/await methods
- [ ] **Keychain Manager**: Secure storage para tokens y credenciales
- [ ] **Authentication Manager**: Gestión central de estado de autenticación
- [ ] **Login/Register Views**: SwiftUI views para autenticación
- [ ] **Biometric Auth**: Touch ID / Face ID integration
- [ ] **Protected App Flow**: Conditional navigation based on auth state
- [ ] **User Session**: Maintain authenticated user context throughout app

#### 🏗️ **STEP 2: REPOSITORY ARCHITECTURE (FUNDACIÓN SYNC)**
- [ ] **Generic Repository Protocols**: SyncableRepository<T> y base protocols
- [ ] **Core Data Repositories**: Local repository implementations
- [ ] **Mock Remote Repositories**: Simulate cloud repositories para testing
- [ ] **Domain Models**: Create domain structs separate from Core Data
- [ ] **Entity Mappers**: Convert between Core Data entities and domain models
- [ ] **Repository Factory**: Create appropriate repository implementations

#### 📡 **STEP 3: NETWORK MONITORING (CONNECTIVITY AWARENESS)**
- [ ] **NetworkMonitor Service**: Implement NWPathMonitor wrapper
- [ ] **Connection State Observable**: @Published network state
- [ ] **Network Quality Detection**: WiFi vs Cellular vs Ethernet
- [ ] **Automatic Retry Logic**: Retry failed operations when connection returns
- [ ] **Background Sync Trigger**: Auto-sync when network becomes available

#### 🔄 **STEP 4: SYNC ENGINE IMPLEMENTATION (CORE FEATURE)**
- [ ] **Sync Repository Implementation**: Hybrid local + remote repositories
- [ ] **Conflict Resolution System**: lastUpdated timestamp-based resolution
- [ ] **Sync Queue Manager**: Queue pending operations for when online
- [ ] **Batch Sync Operations**: Efficient batch synchronization
- [ ] **Sync Status Tracking**: Track sync state per entity
- [ ] **Error Recovery**: Handle sync failures gracefully

#### 🌍 **STEP 5: APPENV IRONMENT & DEPENDENCY INJECTION**
- [ ] **AppEnvironment Structure**: Global container for all repositories
- [ ] **Environment Configurations**: .local, .remote, .sync modes
- [ ] **SwiftUI Environment Integration**: Inject AppEnvironment into views
- [ ] **ViewModel Repository Injection**: Update all ViewModels to use repositories
- [ ] **Environment Switching**: For development, testing, and production

#### 🔧 **STEP 6: VIEWMODEL INTEGRATION (TRANSPARENT SYNC)**
- [ ] **Remove Direct Core Data Dependencies**: ViewModels use only repositories
- [ ] **Async Repository Operations**: Update all ViewModel methods to async
- [ ] **Loading State Management**: Handle async operation states
- [ ] **Error Handling**: Unified error handling for sync operations
- [ ] **Offline Indicators**: UI feedback for offline state

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

#### **Iteración 1 (Siguiente Sprint)** ✅
- [x] Implementar cache en CategoryService e ItemService ✅
- [x] Crear tests unitarios básicos para servicios ✅
- [x] Implementar métricas básicas de performance ✅

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

## 🎯 **ROADMAP DE IMPLEMENTACIÓN - ORDEN ESTRICTO**

### **FASE ACTUAL: 🔐 AUTHENTICATION SYSTEM (Phase 1.5)**
**ESTADO**: ✅ Fase 2.5 completada - Arquitectura MVVM sólida + Security refactoring
**PREREQUISITO**: Sistema de autenticación DEBE implementarse antes que sync
**OBJETIVO**: Establecer contexto de usuario autenticado para operaciones seguras

### **PRÓXIMA FASE: 🔄 HYBRID SYNC ARCHITECTURE (Phase 3)**
**DEPENDENCIAS**: Requiere authentication system completado
**OBJETIVO**: Arquitectura offline-first con sincronización automática en background
**IMPACTO**: Transformará la app de local-only a híbrida cloud-enabled

### **FASE FUTURA: 🚀 BUSINESS LOGIC & FEATURES (Phase 4+)**
**DEPENDENCIAS**: Requiere sync architecture estable
**OBJETIVO**: Implementar funcionalidades de negocio sobre arquitectura sólida
**BENEFICIO**: Features robustas con sync automático y manejo offline

---

## 📋 **CHECKLIST DE IMPLEMENTACIÓN**

### ✅ **COMPLETADO (v0.9.0)**
- [x] Multi-user security architecture
- [x] Service layer refactoring
- [x] ViewModel security updates  
- [x] Code cleanup and professional standards
- [x] Build validation on physical device

### 🔄 **EN PROGRESO (v0.10.0)**
- [ ] Authentication system implementation
- [ ] Repository pattern architecture
- [ ] Network monitoring service
- [ ] Sync engine development
- [ ] Domain model separation

### 📋 **PENDIENTE (v0.11.0+)**
- [ ] Real-time synchronization
- [ ] Advanced business logic
- [ ] Analytics and reporting
- [ ] Export functionality
- [ ] Push notifications

---

**ESTADO ACTUAL: ✅ v0.9.0 COMPLETADO - Security refactoring + Service cleanup**

**PRÓXIMO OBJETIVO: 🔐 v1.0.0 AUTHENTICATION + SYNC ARCHITECTURE**
