import SwiftUI
import CoreData

struct DetailedGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DetailedGroupViewModel
    @State private var showingCreateGroup = false
    @State private var showingSettings = false
    
    init(context: NSManagedObjectContext) {
        let userService = UserService(context: context)
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        let entryService = EntryService(context: context)
        let itemService = ItemService(context: context)
        let categoryService = CategoryService(context: context)
        
        self._viewModel = StateObject(wrappedValue: DetailedGroupViewModel(
            context: context,
            userService: userService,
            groupService: groupService,
            userGroupService: userGroupService,
            entryService: entryService,
            itemService: itemService,
            categoryService: categoryService
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Settings button
                HStack {
                    Spacer()
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                
                // Main Content
                if viewModel.isLoading {
                    LoadingView(message: "Cargando datos...")
                        .padding()
                } else if viewModel.users.isEmpty {
                    // No users exist
                    VStack(spacing: 16) {
                        Text("No hay usuarios creados")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Crear Primer Usuario") {
                            Task {
                                await viewModel.createDefaultUser()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // User and Group Selection
                    VStack(spacing: 16) {
                        // User Selection Dropdown
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Usuario")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Usuario", selection: $viewModel.selectedUser) {
                                Text("Seleccionar Usuario").tag(nil as User?)
                                ForEach(viewModel.users) { user in
                                    Text(user.name ?? "Sin nombre").tag(user as User?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.selectedUser) { _, newUser in
                                if let user = newUser {
                                    Task {
                                        await viewModel.selectUser(user)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Group Selection Dropdown (only show if user is selected)
                        if viewModel.selectedUser != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grupo")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Grupo", selection: $viewModel.selectedGroup) {
                                    Text("Seleccionar Grupo").tag(nil as Group?)
                                    ForEach(userGroupsForSelectedUser, id: \.id) { group in
                                        Text(group.name ?? "Sin nombre").tag(group as Group?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.selectedGroup) { _, newGroup in
                                    if let group = newGroup {
                                        Task {
                                            await viewModel.calculateTotalForGroup(group)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Create Group Button
                            Button("Crear Nuevo Grupo") {
                                showingCreateGroup = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                    }
                }
                

                
                // Total Spent Widget
                if let group = viewModel.selectedGroup {
                    VStack {
                        Text("Total Gastado")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isCalculatingTotal {
                            StyledLoadingView(message: "", style: .compact)
                        } else {
                            Text(viewModel.formatCurrency(viewModel.groupTotal, currency: group.currency ?? "USD"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onAppear {
                        Task {
                            await viewModel.calculateTotalForGroup(group)
                        }
                    }
                    
                    // Entries List
                    List {
                        ForEach(viewModel.entries, id: \.id) { entry in
                            EntryRowView(entry: entry, context: viewContext)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    Spacer()
                    Text("Selecciona un grupo para ver los gastos")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    Spacer()
                }
            }
            .navigationTitle("OMOMoney")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCreateGroup) {
            if let selectedUser = viewModel.selectedUser {
                CreateGroupView(context: viewContext, user: selectedUser)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings, navigationPath: .constant(NavigationPath()))
        }
        .task {
            await viewModel.loadData()
            await viewModel.autoSelectFirstUserAndGroup()
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
    
    // MARK: - Computed Properties
    
    /// Get groups for the selected user
    private var userGroupsForSelectedUser: [Group] {
        guard let selectedUser = viewModel.selectedUser else { return [] }
        
        // Filter groups that belong to the selected user
        return viewModel.groups.filter { group in
            // Check if the user has access to this group through UserGroup relationship
            return group.userGroups?.contains { userGroup in
                guard let userGroup = userGroup as? UserGroup else { return false }
                return userGroup.user?.id == selectedUser.id
            } ?? false
        }
    }
    

}

#Preview {
    DetailedGroupView(context: PersistenceController.preview.container.viewContext)
}
