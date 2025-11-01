import SwiftUI
import CoreData

struct AddItemListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let user: User
    let group: Group
    @Binding var navigationPath: NavigationPath
    
    @StateObject private var viewModel: AddItemListViewModel
    @State private var showingCategoryPicker = false
    @State private var showingPaymentMethodPicker = false
    
    init(user: User, group: Group, context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>) {
        self.user = user
        self.group = group
        self._navigationPath = navigationPath
        
        let itemListService = ItemListService(context: context)
        let categoryService = CategoryService(context: context)
        let itemService = ItemService(context: context)
        let paymentMethodService = PaymentMethodService(context: context)
        
        self._viewModel = StateObject(wrappedValue: AddItemListViewModel(
            itemListService: itemListService,
            categoryService: categoryService,
            itemService: itemService,
            paymentMethodService: paymentMethodService
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // ItemList Details Form
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
                
                // Payment Method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Método de Pago")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingPaymentMethodPicker = true
                    }) {
                        HStack {
                            Image(systemName: paymentMethodIcon(for: viewModel.selectedPaymentMethod?.type ?? ""))
                                .foregroundColor(paymentMethodColor(for: viewModel.selectedPaymentMethod?.type ?? ""))
                                .font(.title2)
                            
                            Text(viewModel.selectedPaymentMethod?.name ?? "Seleccionar Método de Pago")
                                .foregroundColor(viewModel.selectedPaymentMethod != nil ? .primary : .secondary)
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                
                // Group Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grupo")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(group.name ?? "Sin nombre")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("(No se puede cambiar)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Save Button
            Button(action: {
                Task {
                    await saveItemList()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Guardar ItemList")
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
        .navigationTitle("Nuevo ItemList")
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
        .sheet(isPresented: $showingPaymentMethodPicker) {
            PaymentMethodPickerView(
                selectedPaymentMethod: $viewModel.selectedPaymentMethod,
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
            await viewModel.loadPaymentMethods(for: group)
        }
    }
    
    // MARK: - Actions
    
    private func saveItemList() async {
        guard let category = viewModel.selectedCategory else { return }
        
        let success = await viewModel.createItemList(
            description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: viewModel.date,
            category: category,
            group: group,
            paymentMethod: viewModel.selectedPaymentMethod
        )
        
        if success {
            // ✅ SUCCESS: ItemList creado exitosamente
            // Ahora regresamos a la vista anterior
            navigationPath.removeLast()
        }
    }
    
    // MARK: - Helper Methods
    
    private func paymentMethodIcon(for type: String) -> String {
        switch type.lowercased() {
        case "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "transfer":
            return "arrow.left.arrow.right"
        case "digital":
            return "iphone"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func paymentMethodColor(for type: String) -> Color {
        switch type.lowercased() {
        case "card":
            return .blue
        case "cash":
            return .green
        case "transfer":
            return .orange
        case "digital":
            return .purple
        default:
            return .gray
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
    
    return AddItemListView(user: user, group: group, context: context, navigationPath: .constant(NavigationPath()))
}
