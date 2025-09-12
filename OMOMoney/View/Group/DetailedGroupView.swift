import CoreData
import SwiftUI

struct DetailedGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DetailedGroupViewModel
    @Binding var navigationPath: NavigationPath
    let canAccessSettings: Bool
    @State private var showingCreateFirstUser = false
    
    init(context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>, canAccessSettings: Bool = false) {
        let userService = UserService(context: context)
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        let itemListService = ItemListService(context: context)
        let itemService = ItemService(context: context)
        let categoryService = CategoryService(context: context)
        
        self._viewModel = StateObject(wrappedValue: DetailedGroupViewModel(
            context: context,
            userService: userService,
            groupService: groupService,
            userGroupService: userGroupService,
            itemListService: itemListService,
            itemService: itemService,
            categoryService: categoryService
        ))
        self._navigationPath = navigationPath
        self.canAccessSettings = canAccessSettings
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Settings button
            HStack {
                Spacer()
                if canAccessSettings {
                    Button(
                        action: { 
                            // ✅ NAVEGACIÓN REAL: Navegar a SettingsView
                            navigationPath.append(SettingsDestination.settings)
                        },
                        label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    )
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
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No hay usuarios creados")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Crea tu primer usuario para empezar a usar OMOMoney")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Crear Primer Usuario") {
                        showingCreateFirstUser = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if viewModel.selectedUser == nil || viewModel.selectedGroup == nil {
                // Waiting for auto-selection
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Configurando usuario y grupo...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Por favor espera mientras se selecciona automáticamente")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
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
                            ForEach(viewModel.users) { user in
                                Text(user.name ?? "Sin nombre").tag(user as User?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.selectedUser) { _, newUser in
                            if let user = newUser {
                                print("🔄 Usuario seleccionado en UI: \(user.name ?? "Sin nombre")")
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
                                ForEach(userGroupsForSelectedUser, id: \.id) { group in
                                    Text(group.name ?? "Sin nombre").tag(group as Group?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                                                    .onChange(of: viewModel.selectedGroup) { _, newGroup in
                            if let group = newGroup {
                                Task {
                                    await viewModel.calculateTotalForGroup(group)
                                    await viewModel.loadItemListsForSelectedGroup()
                                }
                            }
                        }
                        }
                        .padding(.horizontal)
                        
                        // Create Group Button
                        Button("Crear Nuevo Grupo") {
                            // ✅ NAVEGACIÓN REAL: Navegar a CreateGroupView con usuario
                            if let selectedUser = viewModel.selectedUser {
                                navigationPath.append(CreateGroupDestination.createGroup(selectedUser))
                            }
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
                        await viewModel.loadItemListsForSelectedGroup()
                    }
                }
                
                // Add New ItemList Button
                Button(action: {
                    // ✅ NAVEGACIÓN REAL: Navegar a AddItemListView con usuario y grupo
                    if let user = viewModel.selectedUser, let group = viewModel.selectedGroup {
                        navigationPath.append(AddItemListDestination.addItemList(user, group))
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Agregar Nuevo ItemList")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // ItemLists List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Gastos del Grupo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                                                VStack(alignment: .trailing, spacing: 2) {
                            Text("\(viewModel.itemLists.count) gastos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if viewModel.hasMoreItemLists {
                                Text("+ más disponibles")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoadingItemLists && viewModel.itemLists.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Cargando gastos...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else if viewModel.itemLists.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No hay gastos registrados")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Añade tu primer gasto usando el botón de arriba")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.itemLists, id: \.id) { itemList in
                                    ItemListRowView(
                                        itemList: itemList, 
                                        context: viewContext, 
                                        groupCurrency: group.currency ?? "USD"
                                    )
                                    .padding(.horizontal)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                
                                // Loading indicator for next page
                                if viewModel.isLoadingItemLists {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Cargando más gastos...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                
                                // Load more button
                                if viewModel.hasMoreItemLists && !viewModel.isLoadingItemLists {
                                    Button(action: {
                                        Task {
                                            await viewModel.loadMoreItemLists()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle")
                                            Text("Cargar más gastos")
                                        }
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 400)
                        .refreshable {
                            await viewModel.refreshItemLists()
                        }
                    }
                }
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
        .task {
            await viewModel.loadData()
            await viewModel.maintainSelectedGroup()
        }
        .onAppear {
            // ✅ REFRESH: Refrescar datos cuando la vista aparezca
            Task {
                await viewModel.loadData()
                await viewModel.refreshItemListsAfterCreation()
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
        .sheet(isPresented: $showingCreateFirstUser) {
            CreateFirstUserView(isPresented: $showingCreateFirstUser)
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
    DetailedGroupView(
        context: PersistenceController.preview.container.viewContext,
        navigationPath: .constant(NavigationPath()),
        canAccessSettings: true
    )
}
