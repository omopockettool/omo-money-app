import CoreData
import Foundation
import Combine

/// ViewModel for Detailed Group functionality
/// Handles group detail display, user management, and itemList display
@MainActor
class DetailedGroupViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    // MARK: - Published Properties
    @Published var selectedUser: User?
    @Published var selectedGroup: Group?
    @Published var groupTotal = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var users: [User] = []
    @Published var groups: [Group] = []
    @Published var itemLists: [ItemList] = []
    @Published var isLoadingItemLists = false
    @Published var hasMoreItemLists = true
    @Published var currentPage = 0
    private let itemListsPerPage = 20
    
    // Flag para evitar múltiples ejecuciones simultáneas
    private var isAutoSelecting = false
    
    // MARK: - NSFetchedResultsController
    private var itemListsFetchedResultsController: NSFetchedResultsController<ItemList>?
    
    // MARK: - Group Creation State
    @Published var isCreatingGroup = false
    @Published var groupCreationError: String?
    @Published var groupCreationSuccess = false
    @Published var shouldNavigateBack = false
    
    // MARK: - Services
    let context: NSManagedObjectContext
    let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let itemListService: any ItemListServiceProtocol
    private let itemService: any ItemServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, userService: any UserServiceProtocol, groupService: any GroupServiceProtocol, userGroupService: any UserGroupServiceProtocol, itemListService: any ItemListServiceProtocol, itemService: any ItemServiceProtocol, categoryService: any CategoryServiceProtocol) {
        // ✅ INIT: Inicializar todas las propiedades let antes de super.init()
        self.context = context
        self.userService = userService
        self.groupService = groupService
        self.userGroupService = userGroupService
        self.itemListService = itemListService
        self.itemService = itemService
        self.categoryService = categoryService
        
        super.init()
        
        // ✅ NSFetchedResultsController: Configurar para reactividad automática
        setupItemListsFetchedResultsController()
    }
    
    // MARK: - Public Methods
    
    /// Load data for the application
    func loadData() async {
        // Evitar múltiples ejecuciones simultáneas
        guard !isLoading else {
            print("⚠️ loadData ya está en ejecución, saltando...")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔄 Cargando datos iniciales...")
        
        do {
            // Load users and groups
            users = try await userService.fetchUsers()
            print("✅ Usuarios cargados: \(users.count)")
            
            groups = try await groupService.fetchGroups()
            print("✅ Grupos cargados: \(groups.count)")
        } catch {
            print("❌ ERROR cargando datos: \(error.localizedDescription)")
            errorMessage = "Error loading data: \(error.localizedDescription)"
        }
        
        isLoading = false
        
        // Auto-select user and group after loading data
        if selectedUser == nil || selectedGroup == nil {
            print("🔄 Iniciando auto-selección después de cargar datos...")
            await autoSelectFirstUserAndGroup()
        }
    }
    
    /// Get user groups for a specific group
    func userGroups(for group: Group) async -> [UserGroup] {
        do {
            return try await userGroupService.getUserGroups(for: group)
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get groups for a specific user
    func groups(for user: User) async -> [Group] {
        do {
            let userGroups = try await userGroupService.getGroups(for: user)
            print("📊 Grupos obtenidos para usuario \(safeUserName(user)): \(userGroups.count)")
            
            // Log adicional para debuggear
            if userGroups.isEmpty {
                print("⚠️ ADVERTENCIA: Usuario \(safeUserName(user)) no tiene grupos asignados")
            } else {
                for (index, group) in userGroups.enumerated() {
                    print("  📁 Grupo \(index + 1): \(safeGroupName(group))")
                }
            }
            
            return userGroups
        } catch {
            print("❌ ERROR obteniendo grupos: \(error.localizedDescription)")
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Auto-select first user and first group
    func autoSelectFirstUserAndGroup() async {
        // Evitar múltiples ejecuciones simultáneas
        guard !isAutoSelecting else {
            print("⚠️ autoSelectFirstUserAndGroup ya está en ejecución, saltando...")
            return
        }
        
        isAutoSelecting = true
        print("🔄 Iniciando auto-selección de usuario y grupo...")
        
        // Wait for users to be loaded if empty
        if users.isEmpty {
            print("📥 Cargando datos...")
            await loadData()
        }
        
        guard !users.isEmpty else { 
            print("❌ ERROR: No hay usuarios disponibles para seleccionar")
            return 
        }
        
        // Auto-select first user
        guard let firstUser = users.first else { 
            print("❌ ERROR: No se pudo obtener el primer usuario")
            return 
        }
        
        // Validar que el usuario sea válido
        guard !firstUser.isDeleted else {
            print("❌ ERROR: Usuario marcado para eliminar")
            return
        }
        
        print("✅ Usuario seleccionado automáticamente: \(safeUserName(firstUser))")
        selectedUser = firstUser
        
        // Get groups for the first user
        let userGroups = await groups(for: firstUser)
        
        if let firstGroup = userGroups.first {
            print("🔍 Grupo encontrado: \(safeGroupName(firstGroup))")
            
            selectedGroup = firstGroup
            print("✅ Grupo seleccionado automáticamente: \(safeGroupName(firstGroup))")
            
            // Load itemLists and calculate total for the selected group
            await loadItemListsForSelectedGroup()
            await calculateTotalForGroup(firstGroup)
        } else {
            print("⚠️ Usuario seleccionado pero no tiene grupos")
        }
        
        isAutoSelecting = false
    }
    
    /// Maintain selected group state (ensure user and group are always selected)
    func maintainSelectedGroup() async {
        // Only auto-select if we don't have both user and group
        if selectedUser == nil || selectedGroup == nil {
            print("🔄 Configurando usuario y grupo automáticamente...")
            // Don't call loadData() again if we already have users
            if !users.isEmpty {
                await autoSelectFirstUserAndGroup()
            } else {
                // Only load data if we don't have users
                await loadData()
            }
        }
    }
    
    /// Select a user and load their groups
    func selectUser(_ user: User) async {
        print("🔄 Cambiando usuario a: \(safeUserName(user))")
        selectedUser = user
        selectedGroup = nil // Reset selected group
        
        // Load groups for the selected user
        let userGroups = await groups(for: user)
        
        // Auto-select first group for the new user
        if let firstGroup = userGroups.first {
            print("✅ Seleccionando primer grupo para nuevo usuario: \(safeGroupName(firstGroup))")
            selectedGroup = firstGroup
            
            // Load itemLists and calculate total for the selected group
            await loadItemListsForSelectedGroup()
            await calculateTotalForGroup(firstGroup)
        } else {
            print("⚠️ Usuario no tiene grupos disponibles")
        }
    }
    

    
    /// Get itemLists for a specific group
    func itemLists(for group: Group) async -> [ItemList] {
        guard group.id != nil else { return [] }
        
        do {
            return try await itemListService.getItemLists(for: group)
        } catch {
            errorMessage = "Error loading itemLists: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Calculate total spent for a specific group
    func totalSpent(for group: Group) async -> NSDecimalNumber {
        guard group.id != nil else { return NSDecimalNumber.zero }
        
        do {
            return try await itemService.calculateTotalAmount(for: group)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    /// Calculate total for a specific group
    func calculateTotalForGroup(_ group: Group) async {
        // Evitar recalcular si ya estamos calculando
        guard !isCalculatingTotal else { return }
        
        // Evitar recalcular si ya tenemos el total para el mismo grupo
        if let currentGroup = selectedGroup, 
           currentGroup.id == group.id, 
           groupTotal != NSDecimalNumber.zero {
            return
        }
        
        isCalculatingTotal = true
        errorMessage = nil
        
        do {
            groupTotal = try await itemService.calculateTotalAmount(for: group)
            // ✅ NO sobrescribir itemLists aquí - mantener la paginación
            // itemLists = try await itemListService.getItemLists(for: group)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
        }
        
        isCalculatingTotal = false
    }
    
    /// Calculate total in background
    func calculateTotalInBackground(for group: Group) async {
        await calculateTotalForGroup(group)
    }
    
    /// Refresh data after group creation
    func refreshDataAfterGroupCreation() async {
        do {
            // Reload groups to include the newly created one
            groups = try await groupService.fetchGroups()
            
            // If we have a selected user, try to find their newly created group
            if let selectedUser = selectedUser {
                let userGroups = await groups(for: selectedUser)
                if let newestGroup = userGroups.last {
                    selectedGroup = newestGroup
                    await calculateTotalForGroup(newestGroup)
                }
            }
        } catch {
            errorMessage = "Error refreshing data: \(error.localizedDescription)"
        }
    }
    
    /// Create a new group with default categories
    func createGroup(name: String, currency: String, user: User) async {
        isCreatingGroup = true
        groupCreationError = nil
        groupCreationSuccess = false
        
        do {
            // Create the group
            let newGroup = try await groupService.createGroup(name: name, currency: currency)
            
            // Create the user-group relationship
            _ = try await userGroupService.createUserGroup(user: user, group: newGroup, role: "owner")
            
            // Create default categories for the new group
            let defaultCategories = [
                ("Comida", "#FF6B6B"),
                ("Transporte", "#4ECDC4"),
                ("Entretenimiento", "#45B7D1"),
                ("Compras", "#96CEB4"),
                ("Salud", "#FFEAA7"),
                ("Otros", "#8E8E93")
            ]
            
            for (categoryName, categoryColor) in defaultCategories {
                _ = try await categoryService.createCategory(name: categoryName, color: categoryColor, group: newGroup)
            }
            
            // ✅ REACTIVO: Actualizar el array @Published automáticamente
            groups.append(newGroup)
            
            // ✅ REACTIVO: SwiftUI se actualiza automáticamente
            selectedGroup = newGroup
            groupCreationSuccess = true
            shouldNavigateBack = true
            
        } catch {
            groupCreationError = "Error creating group: \(error.localizedDescription)"
        }
        
        isCreatingGroup = false
    }
    
    /// Create default user for first-time setup
    func createDefaultUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let defaultUser = try await userService.createUser(name: "Usuario Principal", email: "usuario@omomoney.com")
            users = [defaultUser]
            
            // Create default group
            let defaultGroup = try await groupService.createGroup(name: "Grupo Principal", currency: "USD")
            _ = try await userGroupService.createUserGroup(user: defaultUser, group: defaultGroup, role: "owner")
            groups = [defaultGroup]
            
            // Select the default group
            selectedGroup = defaultGroup
        } catch {
            errorMessage = "Error creating default user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create test user for development/testing
    func createTestUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create test user with random data
            let testNames = ["Juan Pérez", "María García", "Carlos López", "Ana Martínez", "Luis Rodríguez"]
            let testEmails = ["juan@test.com", "maria@test.com", "carlos@test.com", "ana@test.com", "luis@test.com"]
            
            let randomIndex = Int.random(in: 0..<testNames.count)
            let testName = testNames[randomIndex]
            let testEmail = testEmails[randomIndex]
            
            let testUser = try await userService.createUser(name: testName, email: testEmail)
            users.append(testUser)
            
            // Create test group if none exist
            if groups.isEmpty {
                let testGroup = try await groupService.createGroup(name: "Grupo de Prueba", currency: "USD")
                _ = try await userGroupService.createUserGroup(user: testUser, group: testGroup, role: "owner")
                groups = [testGroup]
                
                // Select the test group
                selectedGroup = testGroup
            }
            
            // Create some test categories
            let testCategories = [
                ("Comida", "#FF6B6B"),
                ("Transporte", "#4ECDC4"),
                ("Entretenimiento", "#45B7D1"),
                ("Compras", "#96CEB4"),
                ("Salud", "#FFEAA7")
            ]
            
            for (categoryName, categoryColor) in testCategories {
                guard let firstGroup = groups.first else { continue }
                _ = try await categoryService.createCategory(name: categoryName, color: categoryColor, group: firstGroup)
            }
            
        } catch {
            errorMessage = "Error creating test user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Format currency for display
    func formatCurrency(_ amount: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount) ?? "\(amount) \(currency)"
    }
    
    /// Clear group creation state
    func clearGroupCreationState() {
        groupCreationError = nil
        groupCreationSuccess = false
        shouldNavigateBack = false
        isCreatingGroup = false
    }
    
    /// Load itemLists for the selected group with NSFetchedResultsController
    func loadItemListsForSelectedGroup() async {
        // ✅ VALIDACIÓN: Verificar que selectedGroup exista
        guard let group = selectedGroup else {
            print("❌ ERROR: No hay grupo seleccionado")
            return
        }
        
        isLoadingItemLists = true
        
        // ✅ NSFetchedResultsController: Configurar y ejecutar fetch
        configureItemListsFetchRequest(for: group)
        
        isLoadingItemLists = false
    }
    
    /// Load more itemLists (next page) with NSFetchedResultsController
    func loadMoreItemLists() async {
        guard selectedGroup != nil, hasMoreItemLists, !isLoadingItemLists else { return }
        
        isLoadingItemLists = true
        
        // ✅ NSFetchedResultsController: Cargar más itemLists desde los resultados
        guard let fetchedItemLists = itemListsFetchedResultsController?.fetchedObjects else {
            isLoadingItemLists = false
            return
        }
        
        let nextPage = currentPage + 1
        let startIndex = nextPage * itemListsPerPage
        let endIndex = min(startIndex + itemListsPerPage, fetchedItemLists.count)
        
        if startIndex < fetchedItemLists.count {
            let newItemLists = Array(fetchedItemLists[startIndex..<endIndex])
            itemLists.append(contentsOf: newItemLists)
            currentPage = nextPage
            hasMoreItemLists = endIndex < fetchedItemLists.count
        }
        
        isLoadingItemLists = false
    }
    
    /// Refresh itemLists (pull to refresh)
    func refreshItemLists() async {
        await loadItemListsForSelectedGroup()
    }
    
    /// Refresh itemLists after adding a new one
    func refreshItemListsAfterCreation() async {
        guard let group = selectedGroup else { return }
        
        // ✅ REFRESH: Recargar itemLists y total en paralelo para mejor performance
        await loadItemListsForSelectedGroup()
        await calculateTotalForGroup(group)
    }
    
    /// Force refresh itemLists (for debugging and immediate updates)
    func forceRefreshItemLists() async {
        guard let group = selectedGroup else { return }
        
        // Reset pagination and reload all itemLists
        currentPage = 0
        hasMoreItemLists = true
        
        await loadItemListsForSelectedGroup()
        await calculateTotalForGroup(group)
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Validate Core Data object exists
    private func isValidCoreDataObject(_ object: NSManagedObject?) -> Bool {
        return object != nil
    }
    
    /// Safe access to user name
    private func safeUserName(_ user: User?) -> String {
        guard let user = user else { return "Usuario Nil" }
        return user.name ?? "Sin Nombre"
    }
    
    /// Safe access to group name
    private func safeGroupName(_ group: Group?) -> String {
        guard let group = group else { return "Grupo Nil" }
        return group.name ?? "Sin Nombre"
    }
    
    // Función de reparación eliminada - ya no es necesaria
    
    /// Validate if a group exists
    private func isValidGroup(_ group: Group?) -> Bool {
        return group != nil
    }
    
    // MARK: - NSFetchedResultsController
    
    /// Setup NSFetchedResultsController for automatic Core Data updates
    private func setupItemListsFetchedResultsController() {
        let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \ItemList.date, ascending: false)
        ]
        
        itemListsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        itemListsFetchedResultsController?.delegate = self
    }
    
    /// Configure fetch request for specific group
    private func configureItemListsFetchRequest(for _: Group) {
        // ✅ VALIDACIÓN: Verificar que selectedGroup exista
        guard let group = selectedGroup else {
            print("❌ ERROR: No hay grupo seleccionado")
            return
        }
        
        guard let fetchRequest = itemListsFetchedResultsController?.fetchRequest else { return }
        
        // Filter by group
        fetchRequest.predicate = NSPredicate(format: "group == %@", group)
        
        // Sort by date (most recent first)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \ItemList.date, ascending: false)
        ]
        
        // Perform fetch
        do {
            try itemListsFetchedResultsController?.performFetch()
            updateItemListsFromFetchedResults()
        } catch {
            errorMessage = "Error fetching itemLists: \(error.localizedDescription)"
        }
    }
    
    /// Update itemLists from fetched results
    private func updateItemListsFromFetchedResults() {
        guard let fetchedItemLists = itemListsFetchedResultsController?.fetchedObjects else { return }
        
        // Update itemLists with pagination
        let endIndex = min(itemListsPerPage, fetchedItemLists.count)
        itemLists = Array(fetchedItemLists[0..<endIndex])
        hasMoreItemLists = fetchedItemLists.count > itemListsPerPage
        currentPage = 0
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // ✅ AUTO-UPDATE: Core Data cambió, actualizar itemLists automáticamente
        // Seguir patrón obligatorio: background → operación pesada → main thread para UI
        DispatchQueue.main.async { [weak self] in
            self?.updateItemListsFromFetchedResults()
        }
    }
    
    deinit {
        itemListsFetchedResultsController?.delegate = nil
    }
}
