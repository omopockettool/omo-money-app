# Plan: Dashboard Redesign — Roadmap por Fases

## Context
El dashboard actual tiene un header minimalista (título + gear) con espacio desaprovechado y el gear button solo sirve de debug. El usuario quiere: (1) navegación a gestión de categorías/métodos de pago/usuario DONE, (2) filtros rápidos por categoría estilo Spotify REVOKE, (3) toggle de vista lista/calendario con gasto por día. Es demasiado para una sola sesión — se divide en 3 fases.

## Archivos clave del estado actual
- `Presentation/Scenes/Dashboard/DashboardHeaderView.swift` — header actual: título + gear
- `Presentation/Scenes/Dashboard/DashboardView.swift` — NavigationStack, sheets, mainContentView
- `Presentation/Scenes/Dashboard/DashboardViewModel.swift` — ya publica `categories: [UUID: (name, color)]`, `currentGroup`, `currentUser`
- `Presentation/Scenes/Dashboard/ExpenseListView.swift` — lista con secciones por fecha
- `Presentation/Scenes/Category/` — vistas existentes (pickers, posiblemente no CRUD completo)
- `Presentation/Scenes/PaymentMethod/` — ídem

---

## FASE 3 — Toggle Lista/Calendario con gasto diario
**Objetivo de sesión:** Añadir en el header un toggle para cambiar entre vista de lista (actual) y vista de calendario donde cada día muestra el gasto total. Tap en un día → filtra la lista a ese día.

### 3.1 Estado de vista en DashboardViewModel
```swift
@Published var dashboardMode: DashboardMode = .list
@Published var selectedDate: Date? = nil  // nil = sin filtro de día

enum DashboardMode { case list, calendar }
```
Computed property `activeDateFilteredLists` encadena filtro de categoría + filtro de fecha.

### 3.2 Toggle en el header
Reemplazar el espacio libre del header con un `Picker` segmentado o dos botones icon:
- `list.bullet` → vista lista
- `calendar` → vista calendario

### 3.3 CalendarMonthView
`Presentation/Scenes/Dashboard/CalendarMonthView.swift`:
- Grid 7×N con `LazyVGrid`
- Cada celda: número del día + barra de color o texto con importe (si hay gasto)
- Tap en día con gasto → `selectedDate = date` → la lista se filtra
- Navegar mes con flechas `<` `>`
- Datos: agrupar `itemListTotals` por día usando `Calendar.current.startOfDay`

### 3.4 Transición entre modos
- Animación `.transition(.opacity)` o slide entre lista y calendario
- El filtro de categoría (Fase 2) sigue activo en ambos modos

### Archivos a modificar en Fase 3
- `DashboardViewModel.swift` — `dashboardMode`, `selectedDate`, computed filtered lists
- `DashboardHeaderView.swift` — añadir toggle de modo
- `DashboardView.swift` — mostrar CalendarMonthView o ExpenseListView según modo
- `CalendarMonthView.swift` — nuevo

---

## Orden de implementación recomendado
3. **Sesión 3** → Fase 3 (calendario)

## Verificación por fase
- **Fase 3**: Toggle calendario → ver importes por día → tap día → lista filtrada → back al calendario mantiene selección
