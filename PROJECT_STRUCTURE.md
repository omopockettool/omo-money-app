# OMOMoney - Project Structure Documentation

## 🏗️ **Arquitectura del Proyecto - Simplificada v0.8.0**

### **Estructura de Directorios Actualizada**

```
OMOMoney/
├── Models/
│   ├── CoreData/          # Entidades Core Data (generadas automáticamente)
│   └── Domain/            # Modelos de dominio (si es necesario)
│
├── Services/              # Capa de Servicios (NO ObservableObject)
│   ├── Protocols/         # Protocolos de servicios para DI
│   ├── Implementation/    # Implementaciones concretas
│   └── CoreDataService.swift  # Clase base para servicios
│
├── ViewModel/             # Capa de ViewModels (por dominio)
│   ├── User/
│   │   ├── CreateFirstUserViewModel.swift  # Creación primer usuario
│   │   └── [otros ViewModels...]
│   ├── Group/
│   ├── ItemList/
│   ├── Item/
│   └── Category/
│
├── View/                  # Capa de Vistas SwiftUI (simplificada)
│   ├── MainView.swift            # 🆕 Vista principal simplificada
│   ├── AppContentView.swift      # 🆕 Contenido principal de la app
│   ├── SettingsView.swift        # Configuraciones (simplificado)
│   ├── User/
│   │   ├── CreateFirstUserView.swift  # Modal de primer usuario
│   │   ├── AddUserView.swift
│   │   └── EditUserView.swift
│   ├── Group/
│   ├── ItemList/
│   ├── Base/              # Componentes reusables
│   └── [otras vistas...]
│
├── CoreDataStack/         # Configuración de Core Data
│   └── Persistence.swift
│
├── Utilities/             # Utilidades y extensiones
│   ├── Constants/
│   ├── Extensions/
│   └── Helpers/
│
├── Assets.xcassets/       # Recursos de la aplicación
├── ContentView.swift      # Punto de entrada (usa MainView)
├── OMOMoneyApp.swift      # App entry point
├── OMOMoney.entitlements  # Entitlements
└── OMOMoney.xcdatamodeld/ # Modelo de datos Core Data
```

## 🔄 **Flujo de Arquitectura Simplificada v0.8.0**

### **Flujo Principal de la Aplicación**
```
ContentView → MainView → {
    ¿Sandbox vacío?
    ├── SÍ → CreateFirstUserView (Sheet)
    │        ↓ (Usuario creado)
    │        └── AppContentView
    └── NO → AppContentView directamente
}
```

### **Flujo de Dependencias Simplificado**
```
View → ViewModel → Service (NO Observable) → Core Data
  ↓         ↓              ↓                    ↓
SwiftUI   Business      Pure Data          Persistence
         Logic         Access Layer
```

## 📋 **Nuevas Reglas de Organización v0.8.0**

### **🆕 Views Principales**
- **MainView.swift**: 
  - ✅ Solo manejo de detección de usuario y sheet
  - ✅ Redirección automática a AppContentView
  - ❌ NO navegación compleja ni estado global
  
- **AppContentView.swift**: 
  - ✅ Contenido principal cuando hay usuarios
  - ✅ Dashboard, botones de acción rápida
  - ✅ Navigation interna cuando sea necesario
  
- **CreateFirstUserView.swift**: 
  - ✅ Modal sheet para primer usuario
  - ✅ Callback async para notificar creación
  - ✅ Cierre automático del sheet

### **🔧 Services (Actualizados)**
- **NO ObservableObject**: Los services son clases puras de acceso a datos
- **Inyección por parámetro**: Se pasan al ViewModel en el init
- **Background operations**: Todas las operaciones pesadas en background threads
- **Cache inteligente**: Sistema de cache para optimizar rendimiento

### **⚡ ViewModels (Optimizados)**
- **@MainActor**: Para operaciones que actualizan UI
- **Dependency Injection**: Reciben services como parámetros
- **@StateObject**: Solo en las Views que los crean y poseen
- **Async/await**: Operaciones modernas sin callbacks complejos

## 🎯 **Arquitectura de Navegación Simplificada**

### **Antes (v0.7.0) - Complejo**
```swift
NavigationStack(path: $navigationPath) {
    DetailedGroupView()
        .navigationDestination(for: User.self) { ... }
        .navigationDestination(for: AddUserDestination.self) { ... }
        .navigationDestination(for: CreateGroupDestination.self) { ... }
        .navigationDestination(for: SettingsDestination.self) { ... }
        // ... más destinos complejos
}
```

### **Después (v0.8.0) - Simple**
```swift
// MainView - Solo detección y sheet
ZStack {
    if hasUsers {
        AppContentView(context: context)  // ✅ Simple
    } else {
        EmptyStateView()
    }
}
.sheet(isPresented: $showingCreateFirstUser) {
    CreateFirstUserView()  // ✅ Modal simple
}

// AppContentView - Navegación interna cuando sea necesario
NavigationStack {
    // Contenido principal con botones de acción
}
```

## 🚀 **Beneficios de la Nueva Arquitectura**

### **✅ Simplicidad**
- **75% menos código** en MainView (174 → 109 líneas)
- **Navegación directa** sin enums complejos
- **Flujo claro** de usuario: vacío → crear → usar app

### **✅ Mantenibilidad**
- **Separación clara** entre detección de usuario y contenido principal
- **Testing más fácil** con menos dependencias
- **Debugging simplificado** con flujo lineal

### **✅ Performance**
- **Carga más rápida** sin navegación compleja inicial
- **Menos overhead** de memoria con arquitectura simplificada
- **UI responsiva** con async callbacks optimizados

### **✅ Escalabilidad**
- **Base sólida** para agregar funcionalidades
- **AppContentView preparada** para crecimiento futuro
- **Estructura modular** para nuevas características

## 🔄 **Migración de Funcionalidades**

### **✅ Completado en v0.8.0**
- [x] Simplificación de MainView
- [x] Creación de AppContentView
- [x] Flujo de primer usuario optimizado
- [x] Eliminación de navegación compleja
- [x] Corrección de async callbacks

### **📋 Pendiente para v0.9.0**
- [ ] Implementar navegación interna en AppContentView
- [ ] Restaurar funcionalidades de Settings
- [ ] Agregar funcionalidades de dashboard
- [ ] Implementar gestión de grupos en AppContentView

---

**Esta estructura v0.8.0 está optimizada para simplicidad, mantenibilidad y crecimiento futuro, eliminando la complejidad innecesaria mientras mantiene toda la funcionalidad core.**
