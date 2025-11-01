// 🧩 Arquitectura base solicitada
//
// Objetivo: Configurar una capa de datos híbrida (offline-first) en mi app actual.
//
// Contexto:
// - Ya existen las entidades del modelo (Core Data y structs).
// - Ya estoy usando MVVM.
// - Los ViewModels dependen de protocolos (no de implementaciones concretas).
//
// Instrucciones:
//
// 1. Crear una capa de sincronización genérica basada en protocolos.
//
//    - Define un protocolo genérico `SyncableRepository<T>` donde T es la entidad del dominio.
//    - Este protocolo debe combinar dos repositorios:
//        - Uno local (ej. CoreDataRepository<T>)
//        - Uno remoto (ej. CloudRepository<T>)
//    - Si no hay conexión, usa el local.
//    - Si hay conexión, sincroniza automáticamente los cambios locales con el remoto (en background).
//    - La sincronización debe considerar una propiedad `lastUpdated` o similar para decidir qué versión prevalece.
//
// 2. Implementar un monitor de conexión a internet.
//
//    - Usa `NWPathMonitor` para detectar el estado de la red.
//    - Expone un `NetworkMonitor.shared.isConnected` observable (por ejemplo con `@Published` o `@MainActor @Observable`).
//
// 3. Crear una estructura `AppEnvironment` global.
//
//    - Debe contener todos los repositorios que usa la app (los mismos que ya existen).
//    - Incluir tres configuraciones de entorno:
//        - `.local`: usa solo repositorios Core Data.
//        - `.remote`: usa solo repositorios remotos.
//        - `.sync`: usa repositorios híbridos (`SyncRepository`) que combinan ambos.
//    - Permitir inyección de este environment en SwiftUI usando `.environment(\.appEnvironment, value)`.
//
// 4. Integración con los ViewModels.
//
//    - Asegúrate de que los ViewModels sigan dependiendo solo de protocolos (`UserRepository`, `ProjectRepository`, etc.).
//    - No deben saber si el repositorio es local, remoto o híbrido.
//    - En la inicialización de la app, inyectar el `AppEnvironment.sync` como valor por defecto.
//
// 5. Flujo de sincronización.
//
//    - Cuando el `NetworkMonitor` detecte que vuelve la conexión, dispara un proceso de sync global.
//    - Cada `SyncRepository` debe tener un método `syncPendingChanges()` que se encargue de subir lo pendiente.
//
// 6. Requisitos técnicos.
//
//    - Usa async/await en los repositorios.
//    - Marca las clases como `Sendable` donde corresponda.
//    - Asegura que los métodos que tocan la UI estén en `@MainActor`.
//    - Documenta cada tipo con un comentario corto para claridad.
//
// Resultado esperado:
// - Código listo para producción, bien organizado, reutilizable y fácil de escalar.
// - MVVM sigue igual de limpio: las vistas y ViewModels no cambian, solo se añade la capa de sincronización.
//
// Fin de instrucciones.
