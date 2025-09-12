# OMOMoney - Project Structure Documentation

## 🏗️ **Arquitectura del Proyecto para Escalabilidad**

### **Estructura de Directorios**

```
OMOMoney/
├── Models/
│   ├── CoreData/          # Entidades Core Data (generadas automáticamente)
│   └── Domain/            # Modelos de dominio (si es necesario)
│
├── Services/              # Capa de Servicios
│   ├── Protocols/         # Protocolos de servicios para DI
│   ├── Implementation/    # Implementaciones concretas
│   └── CoreDataService.swift  # Clase base para servicios
│
├── ViewModel/             # Capa de ViewModels (por dominio)
│   ├── User/
│   ├── Group/
│   ├── Entry/
│   ├── Item/
│   └── Category/
│
├── View/                  # Capa de Vistas SwiftUI (por dominio)
│   ├── User/
│   ├── Group/
│   ├── Entry/
│   ├── Base/
│   ├── MainView.swift
│   └── SettingsView.swift
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
├── ContentView.swift      # Vista principal
├── OMOMoneyApp.swift      # App entry point
├── OMOMoney.entitlements  # Entitlements
└── OMOMoney.xcdatamodeld/ # Modelo de datos Core Data
```

## 🔄 **Flujo de Dependencias**

```
View → ViewModel → Service Protocol ← Service Implementation → Core Data
  ↓         ↓              ↓                    ↓              ↓
SwiftUI   Business      Interface          Concrete      Persistence
         Logic         Contract           Implementation
```

## 📋 **Reglas de Organización**

- **Services/**: Protocolos en `Protocols/`, implementaciones en `Implementation/`, base común en `CoreDataService.swift`.
- **ViewModel/**: Un ViewModel por archivo, organizados por dominio.
- **View/**: Una vista por archivo, organizadas por dominio y componentes reusables en `Base/`.
- **Models/**: Entidades Core Data y modelos de dominio si se requieren.
- **Utilities/**: Constantes, extensiones y helpers.
- **CoreDataStack/**: Configuración y stack de Core Data.
- **Assets.xcassets/**: Recursos gráficos.

---

**Esta estructura está diseñada para crecer con tu aplicación y mantener el código organizado y mantenible a largo plazo.**
