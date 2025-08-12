import SwiftUI
import CoreData

struct UserListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: UserListViewModel
    @State private var showingAddUser = false
    @State private var navigationPath = NavigationPath()
    
    init(context: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: UserListViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(viewModel.users) { user in
                    NavigationLink(value: user) {
                        UserRowView(user: user)
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
                await viewModel.deleteUser(user)
            }
        }
    }
}

#Preview {
    UserListView(context: PersistenceController.preview.container.viewContext)
}
