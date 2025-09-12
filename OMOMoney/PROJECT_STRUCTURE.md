# OMOMoney - Project Structure Documentation

## 🏗️ **Arquitectura del Proyecto para Escalabilidad**

### **Estructura de Directorios**

```
OMOMoney/
├── 📁 Models/
│   ├── CoreData/          # Entidades Core Data (generadas automáticamente)
│   └── Domain/            # Modelos de dominio (si es necesario)
│
├── 📁 Services/            # Capa de Servicios
│   ├── Protocols/          # Protocolos de servicios para DI
│   │   ├── UserServiceProtocol.swift
│   │   ├── GroupServiceProtocol.swift
│   │   ├── ItemListServiceProtocol.swift
│   │   ├── ItemServiceProtocol.swift
│   │   ├── CategoryServiceProtocol.swift
│   │   └── UserGroupServiceProtocol.swift
│   ├── Implementation/     # Implementaciones concretas
│   │   ├── UserService.swift
│   │   ├── GroupService.swift
│   │   ├── ItemListService.swift
│   │   ├── ItemService.swift
│   │   ├── CategoryService.swift
│   │   └── UserGroupService.swift
│   └── CoreDataService.swift  # Clase base para servicios
│
├── 📁 ViewModels/          # Capa de ViewModels
│   ├── User/               # ViewModels relacionados con usuarios
│   │   ├── UserListViewModel.swift
│   │   ├── CreateUserViewModel.swift
│   │   ├── EditUserViewModel.swift
│   │   └── UserDetailViewModel.swift
│   ├── Group/              # ViewModels relacionados con grupos
│   │   ├── CreateGroupViewModel.swift
│   │   ├── DetailedGroupViewModel.swift
│   │   └── GroupListViewModel.swift
│   ├── ItemList/           # ViewModels relacionados con listas de items
│   │   ├── ItemListListViewModel.swift
│   │   ├── ItemListDetailViewModel.swift
│   │   ├── ItemListRowViewModel.swift
│   │   └── AddItemListViewModel.swift
│   ├── Item/               # ViewModels relacionados con items
│   │   └── ItemListViewModel.swift
│   └── Category/           # ViewModels relacionados con categorías
│       └── CategoryListViewModel.swift
│
├── 📁 View/                # Capa de Vistas SwiftUI
│   ├── User/               # Vistas relacionadas con usuarios
│   │   ├── UserListView.swift
│   │   ├── AddUserView.swift
│   │   ├── EditUserView.swift
│   │   └── UserDetailView.swift
│   ├── Group/              # Vistas relacionadas con grupos
│   │   ├── CreateGroupView.swift
│   │   ├── DetailedGroupView.swift
│   │   └── GroupListView.swift
│   ├── ItemList/           # Vistas relacionadas con listas de items
│   │   ├── ItemListRowView.swift
│   │   └── AddItemListView.swift
│   ├── Base/               # Componentes reusables
│   │   └── Loading/
│   │       └── LoadingView.swift
│   ├── MainView.swift      # Vista principal de navegación
│   └── SettingsView.swift  # Vista de configuración
│
├── 📁 CoreDataStack/       # Configuración de Core Data
│   └── Persistence.swift
│
├── 📁 Utilities/           # Utilidades y extensiones
│   ├── Constants/
│   │   └── AppConstants.swift
│   ├── Extensions/
│   │   ├── Color+Hex.swift
│   │   ├── NSDecimalNumber+Safe.swift
│   │   └── User+Safe.swift
│   └── Helpers/
│       ├── DateFormatterHelper.swift
│       └── ValidationHelper.swift
│
└── 📁 Assets.xcassets/     # Recursos de la aplicación
```

## 🎯 **Beneficios de esta Estructura**

### **1. Escalabilidad**
- **Separación clara**: Cada capa tiene su responsabilidad específica
- **Fácil navegación**: Los desarrolladores pueden encontrar archivos rápidamente
- **Crecimiento organizado**: Nuevas funcionalidades se pueden agregar en directorios apropiados

### **2. Mantenibilidad**
- **Protocolos separados**: Fácil mockear para testing
- **Implementaciones aisladas**: Cambios en servicios no afectan ViewModels
- **Dependencias claras**: Cada componente declara explícitamente sus dependencias

### **3. Testabilidad**
- **Protocolos para DI**: Fácil crear mocks para unit tests
- **Separación de responsabilidades**: Cada capa puede ser testeada independientemente
- **Arquitectura limpia**: Facilita TDD y testing automatizado

### **4. Colaboración en Equipo**
- **Estructura estándar**: Todos los desarrolladores entienden la organización
- **Convenciones claras**: Nombres de archivos y directorios son consistentes
- **Documentación integrada**: La estructura es auto-documentada

### **5. Imports en Swift**
- **Imports automáticos**: En Swift, cuando todos los archivos están en el mismo target, son automáticamente visibles
- **No imports especiales necesarios**: Los protocolos y clases se importan automáticamente dentro del mismo módulo
- **Simplicidad**: Solo necesitamos `import Foundation` e `import CoreData` en cada archivo

## 🔄 **Flujo de Dependencias**

```
View → ViewModel → Service Protocol ← Service Implementation → Core Data
  ↓         ↓              ↓                    ↓              ↓
SwiftUI   Business      Interface          Concrete      Persistence
         Logic         Contract           Implementation
```

## 📋 **Reglas de Organización**

### **Services/**
- **Protocols/**: Solo interfaces, sin implementación
- **Implementation/**: Solo implementaciones concretas
- **CoreDataService.swift**: Clase base para funcionalidad común

### **ViewModels/**
- **Organización por dominio**: User/, Group/, ItemList/, etc.
- **Un ViewModel por archivo**: Mantener archivos pequeños y enfocados
- **Protocolos de servicios**: Usar interfaces, no implementaciones concretas

### **Views/**
- **Organización por dominio**: User/, Group/, ItemList/, etc.
- **Base/**: Componentes reusables (Loading, Error, etc.)
- **Una vista por archivo**: Mantener archivos pequeños y enfocados

### **Models/**
- **Core Data**: Generado automáticamente por Xcode
- **Domain**: Solo si se necesitan modelos adicionales

## 🚀 **Próximos Pasos para Escalabilidad**

1. **Testing Infrastructure**: Crear directorio `Tests/` con estructura paralela
2. **Networking Layer**: Agregar `Services/Networking/` para APIs futuras
3. **Analytics**: Agregar `Services/Analytics/` para tracking
4. **Configuration**: Agregar `Services/Configuration/` para settings
5. **Caching**: Agregar `Services/Caching/` para optimización

---

**Esta estructura está diseñada para crecer con tu aplicación y mantener el código organizado y mantenible a largo plazo.**
