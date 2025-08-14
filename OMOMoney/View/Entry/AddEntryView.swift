import SwiftUI
import CoreData

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let user: User
    let group: Group
    @Binding var navigationPath: NavigationPath
    
    @StateObject private var viewModel: AddEntryViewModel
    @State private var showingCategoryPicker = false
    
    init(user: User, group: Group, context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>) {
        self.user = user
        self.group = group
        self._navigationPath = navigationPath
        
        let entryService = EntryService(context: context)
        let categoryService = CategoryService(context: context)
        let itemService = ItemService(context: context)
        
        self._viewModel = StateObject(wrappedValue: AddEntryViewModel(
            entryService: entryService,
            categoryService: categoryService,
            itemService: itemService
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Entry Details Form
            VStack(alignment: .leading, spacing: 16) {
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Descripción")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Descripción del gasto", text: $viewModel.description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fecha")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categoría")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            Text(viewModel.selectedCategory?.name ?? "Seleccionar Categoría")
                                .foregroundColor(viewModel.selectedCategory != nil ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Save Button
            Button(action: {
                Task {
                    await saveEntry()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Guardar Entry")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSave ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSave)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Nuevo Entry")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancelar") {
                    navigationPath.removeLast()
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                selectedCategory: $viewModel.selectedCategory,
                group: group,
                context: viewContext
            )
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
        .task {
            await viewModel.loadCategories(for: group)
        }
    }
    
    // MARK: - Actions
    
    private func saveEntry() async {
        guard let category = viewModel.selectedCategory else { return }
        
        let success = await viewModel.createEntry(
            description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: viewModel.date,
            category: category,
            group: group
        )
        
        if success {
            navigationPath.removeLast()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let user = User(context: context)
    user.id = UUID()
    user.name = "Test User"
    user.email = "test@example.com"
    
    let group = Group(context: context)
    group.id = UUID()
    group.name = "Test Group"
    group.currency = "USD"
    
    return AddEntryView(user: user, group: group, context: context, navigationPath: .constant(NavigationPath()))
}
