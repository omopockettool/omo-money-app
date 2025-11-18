import SwiftUI
import CoreData

struct AddItemListView: View {
    let user: UserDomain
    let group: GroupDomain
    @Binding var navigationPath: NavigationPath
    let onItemListCreated: (ItemListDomain) -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: AddItemListViewModel
    @State private var showingCategoryPicker = false
    @State private var showingPaymentMethodPicker = false

    init(user: UserDomain, group: GroupDomain, navigationPath: Binding<NavigationPath>, onItemListCreated: @escaping (ItemListDomain) -> Void) {
        self.user = user
        self.group = group
        self._navigationPath = navigationPath
        self.onItemListCreated = onItemListCreated
        print("🔄 AddItemListView: Initializing with Clean Architecture DI")
        self._viewModel = StateObject(wrappedValue: AddItemListViewModel())
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
                        
                        Text(group.name)
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
                group: group.toCoreData(context: viewContext),
                context: viewContext
            )
        }
        .sheet(isPresented: $showingPaymentMethodPicker) {
            PaymentMethodPickerView(
                selectedPaymentMethod: $viewModel.selectedPaymentMethod,
                group: group.toCoreData(context: viewContext),
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
            let groupCD = group.toCoreData(context: viewContext)
            await viewModel.loadCategories(for: groupCD)
            await viewModel.loadPaymentMethods(for: groupCD)
        }
    }
    
    // MARK: - Actions
    
    private func saveItemList() async {
        guard let category = viewModel.selectedCategory else { return }
        
        print("🔄 AddItemListView: Creating ItemList...")
        
        if let createdItemList = await viewModel.createItemList(
            description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: viewModel.date,
            category: category,
            group: group.toCoreData(context: viewContext),
            paymentMethod: viewModel.selectedPaymentMethod
        ) {
            // ✅ SUCCESS: ItemList created successfully
            print("✅ AddItemListView: ItemList created: '\(createdItemList.itemListDescription)'")
            print("🔄 AddItemListView: Calling onItemListCreated callback with ItemList...")
            
            // Pass the created ItemListDomain to the callback for incremental cache update
            onItemListCreated(createdItemList)
            
            print("✅ AddItemListView: Callback executed, navigating back...")
            
            // Delay navigation slightly to avoid NavigationRequestObserver conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationPath.removeLast()
            }
        } else {
            print("❌ AddItemListView: Failed to create ItemList")
        }
    }
    
    // MARK: - Helper Methods
    
    private func paymentMethodIcon(for type: String) -> String {
        switch type.lowercased() {
        case "card_debit", "card_credit", "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "bank_transfer", "transfer":
            return "arrow.left.arrow.right"
        case "digital":
            return "iphone"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func paymentMethodColor(for type: String) -> Color {
        switch type.lowercased() {
        case "card_debit", "card_credit", "card":
            return .blue
        case "cash":
            return .green
        case "bank_transfer", "transfer":
            return .orange
        case "digital":
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    let user = UserDomain(
        id: UUID(),
        name: "Test User",
        email: "test@example.com"
    )
    let group = GroupDomain(
        id: UUID(),
        name: "Test Group",
        currency: "USD"
    )
    AddItemListView(
        user: user,
        group: group,
        navigationPath: .constant(NavigationPath()),
        onItemListCreated: { _ in }
    )
}
