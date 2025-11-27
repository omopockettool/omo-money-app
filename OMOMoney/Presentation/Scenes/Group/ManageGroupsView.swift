import SwiftUI
import CoreData

struct ManageGroupsView: View {
    @Binding var navigationPath: NavigationPath
    let selectedUser: User
    @StateObject private var viewModel: ManageGroupsViewModel
    
    init(navigationPath: Binding<NavigationPath>, selectedUser: User) {
        self._navigationPath = navigationPath
        self.selectedUser = selectedUser
        self._viewModel = StateObject(wrappedValue: ManageGroupsViewModel(selectedUser: selectedUser))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        LoadingView()
                        Spacer()
                    }
                }
            } else if viewModel.groups.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.sequence")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No hay grupos")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Crea tu primer grupo para empezar a gestionar gastos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.groups, id: \.id) { group in
                    GroupRowView(group: group) {
                        // Acción de eliminar
                        viewModel.deleteGroup(group)
                    }
                }
            }
        }
        .navigationTitle("Administrar Grupos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Atrás") {
                    navigationPath.removeLast()
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Error desconocido")
        }
        .onAppear {
            Task {
                await viewModel.loadUserGroups()
            }
        }
    }
}

struct GroupRowView: View {
    let group: Group
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name ?? "Sin nombre")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Moneda: \(group.currency ?? "USD")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let createdAt = group.createdAt {
                    Text("Creado: \(createdAt, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .alert("Eliminar Grupo", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar el grupo '\(group.name ?? "Sin nombre")'? Esta acción no se puede deshacer.")
        }
    }
}

#Preview {
    ManageGroupsView(navigationPath: .constant(NavigationPath()), selectedUser: User())
}
