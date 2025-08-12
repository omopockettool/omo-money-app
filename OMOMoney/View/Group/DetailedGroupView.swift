import SwiftUI
import CoreData

struct DetailedGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DetailedGroupViewModel
    @State private var selectedGroup: Group?
    @State private var showingCreateGroup = false
    @State private var showingSettings = false
    
    init(context: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: DetailedGroupViewModel(context: context))
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
                
                // Group Selection Dropdown
                if let firstUser = viewModel.users.first {
                    Picker("Grupo", selection: $selectedGroup) {
                        Text("Seleccionar Grupo").tag(nil as Group?)
                        ForEach(viewModel.groups) { group in
                            Text(group.name ?? "Sin nombre").tag(group as Group?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    // Create Group Button
                    Button("Crear Nuevo Grupo") {
                        showingCreateGroup = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
                
                // Total Spent Widget
                if let group = selectedGroup {
                    VStack {
                        Text("Total Gastado")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isCalculatingTotal {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(viewModel.formatCurrency(viewModel.groupTotal, group.currency ?? "USD"))
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
                        ForEach(await viewModel.entries(for: group)) { entry in
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
            CreateGroupView(detailedGroupViewModel: viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await viewModel.loadData()
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
}

#Preview {
    DetailedGroupView(context: PersistenceController.preview.container.viewContext)
}
