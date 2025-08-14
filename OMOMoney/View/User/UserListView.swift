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
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.users.enumerated()), id: \.element.id) { index, user in
                        userRow(for: user, at: index)
                    }
                    
                    // Loading indicator for pagination
                    if viewModel.hasMoreUsers {
                        loadingIndicator
                    }
                }
            }
            .navigationTitle("Usuarios")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addUserButton
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView(context: viewContext)
                    .transition(.move(edge: .bottom))
                    .animation(AnimationHelper.slide, value: showingAddUser)
            }
            .navigationDestination(for: User.self) { user in
                EditUserView(user: user, context: viewContext)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .animation(AnimationHelper.slide, value: user.id)
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
                withAnimation(AnimationHelper.fade) {
                    viewModel.clearError()
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .animation(AnimationHelper.smoothSpring, value: viewModel.users.count)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func userRow(for user: User, at index: Int) -> some View {
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
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser(user)
                }
            }
        }
        .onAppear {
            // Load more users when approaching the end
            if user == viewModel.users.last && viewModel.hasMoreUsers {
                Task {
                    await viewModel.loadMoreUsers()
                }
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
        .animation(AnimationHelper.listItem.delay(Double(index) * 0.05), value: user.id)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
                .scaleEffect(1.2)
                .animation(AnimationHelper.pulse, value: viewModel.isLoading)
            Spacer()
        }
        .transition(.opacity.combined(with: .scale))
        .animation(AnimationHelper.fade, value: viewModel.hasMoreUsers)
    }
    
    @ViewBuilder
    private var addUserButton: some View {
        Button(action: { 
            withAnimation(AnimationHelper.scale) {
                showingAddUser = true
            }
        }) {
            Label("Agregar Usuario", systemImage: "plus")
        }
        .buttonPressAnimation()
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
