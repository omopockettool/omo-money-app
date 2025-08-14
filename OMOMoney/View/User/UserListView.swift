import SwiftUI
import CoreData

struct UserListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: UserListViewModel
    @State private var showingAddUser = false
    @State private var navigationPath = NavigationPath()
    
    init(context: NSManagedObjectContext) {
        let userService = UserService(context: context)
        self._viewModel = StateObject(wrappedValue: UserListViewModel(userService: userService))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(viewModel.users) { user in
                    NavigationLink(value: user) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.name ?? "Sin nombre")
                                    .font(.headline)
                                Text(user.email ?? "Sin email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteUsers)
            }
            .navigationTitle("Usuarios")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser = true }) {
                        Label("Agregar Usuario", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView(context: viewContext)
            }
            .navigationDestination(for: User.self) { user in
                EditUserView(user: user, context: viewContext)
            }
            .task {
                await viewModel.loadUsers()
            }
            .refreshable {
                await viewModel.loadUsers()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteUsers(offsets: IndexSet) {
        Task {
            for index in offsets {
                let user = viewModel.users[index]
                let success = await viewModel.deleteUser(user)
                
                // If deletion failed, we could show additional feedback here
                // The ViewModel already handles error messages through @Published errorMessage
                if !success {
                    // The error is already displayed through the alert in the view
                    break
                }
            }
        }
    }
}

#Preview {
    UserListView(context: PersistenceController.preview.container.viewContext)
}
