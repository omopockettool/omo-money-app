# CustomAlertView

Componente de alert customizado y reutilizable con animaciones suaves para toda la app.

## Características

- ✅ Animaciones suaves (spring animation con fade y scale)
- ✅ Estilo iOS nativo
- ✅ Soporte para 3 tipos de botones: `.default`, `.cancel`, `.destructive`
- ✅ Mensaje opcional
- ✅ Cierre al tocar fuera del alert
- ✅ Control total de colores (independiente del accent color)
- ✅ Completamente modular y reutilizable

## Uso Básico

### Con View Extension (Recomendado)

```swift
struct MyView: View {
    @State private var showAlert = false
    
    var body: some View {
        Button("Mostrar Alert") {
            showAlert = true
        }
        .customAlert(
            title: "¿Estás seguro?",
            message: "Esta acción no se puede deshacer",
            isPresented: $showAlert,
            primaryButton: AlertButton(title: "Eliminar", style: .destructive) {
                // Acción de eliminar
            },
            secondaryButton: AlertButton(title: "Cancelar", style: .cancel) {
                // Acción de cancelar
            }
        )
    }
}
```

### Sin Botón Secundario

```swift
.customAlert(
    title: "Operación exitosa",
    message: "Los cambios han sido guardados",
    isPresented: $showSuccess,
    primaryButton: AlertButton(title: "OK", style: .default) {
        // Cerrar
    }
)
```

### Uso Directo del Componente

```swift
if showAlert {
    CustomAlertView(
        title: "Título",
        message: "Mensaje opcional",
        primaryButton: AlertButton(title: "Aceptar", style: .default) {
            // Acción
        },
        secondaryButton: nil,
        isPresented: $showAlert
    )
}
```

## Estilos de Botón

### `.default`
- Color: Accent color de la app
- Peso: Medium
- Uso: Acciones normales

### `.cancel`
- Color: Primary (negro/blanco según dark mode)
- Peso: Regular
- Uso: Cancelar, cerrar

### `.destructive`
- Color: Rojo
- Peso: Semibold
- Uso: Eliminar, acciones irreversibles

## Estructura del Componente

```
CustomAlertView.swift
├── CustomAlertView (View principal)
├── AlertButton (Modelo de botón)
├── AlertButtonStyle (Enum de estilos)
└── View Extension (Helper para uso fácil)
```

## Animaciones

- **Entrada**: Scale de 0.8 a 1.0 + Fade in
- **Salida**: Scale de 1.0 a 0.8 + Fade out
- **Duración**: 0.3s con spring animation
- **Background**: Fade in/out suave del overlay

## Ejemplo Completo

Ver `GroupSelectorChipView.swift` para un ejemplo de implementación real.
