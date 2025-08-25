import SwiftUI

struct SettingsView: View {
    @Binding var navigationPath: NavigationPath
    let selectedUser: User?
    
    var body: some View {
        List {
            Section("Configuración") {
                if let user = selectedUser {
                    Button(action: {
                        navigationPath.append(SettingsDestination.manageGroups(user))
                    }) {
                        HStack {
                            Image(systemName: "person.3.sequence.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
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
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack {
                        Image(systemName: "person.3.sequence.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Administrar Grupos")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Selecciona un usuario primero")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .disabled(true)
                }
                
                // Otros ajustes futuros aquí
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Atrás") {
                    navigationPath.removeLast()
                }
            }
        }
    }
}

#Preview {
    SettingsView(navigationPath: .constant(NavigationPath()), selectedUser: nil)
}
