import SwiftUI

struct SettingsView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 20) {
            // Administrar Usuarios
            Button(
                action: {
                    // ✅ SIMPLIFICADO: Solo navegar de vuelta por ahora
                    // La funcionalidad de agregar usuarios se maneja desde MainView
                },
                label: {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Administrar Usuarios")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Gestionar usuarios de la aplicación")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            // Administrar Grupos
            Button(
                action: {},
                label: {
                    HStack {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Administrar Grupos")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Gestionar grupos de gastos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Atrás") {
                    // ✅ NAVEGACIÓN PROGRAMÁTICA: Usar NavigationPath
                    navigationPath.removeLast()
                }
            }
        }
    }
}
