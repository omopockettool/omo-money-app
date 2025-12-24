import SwiftUI

/// ✅ Clean Architecture: Works with Domain models only, no Core Data dependencies
struct AddItemListView: View {
    let user: UserDomain
    let group: GroupDomain
    let onItemListCreated: (ItemListDomain) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel: AddItemListViewModel

    init(user: UserDomain, group: GroupDomain, onItemListCreated: @escaping (ItemListDomain) -> Void, onCancel: @escaping () -> Void) {
        self.user = user
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onCancel = onCancel
        print("🔄 AddItemListView: Initializing with Clean Architecture DI")
        self._viewModel = StateObject(wrappedValue: AddItemListViewModel())
    }
    
    var body: some View {
        Form {
            Section("Detalles del Gasto") {
                TextField("Descripción", text: $viewModel.description)

                TextField("Precio (opcional)", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isPriceValid ? Color.clear : Color.red, lineWidth: 1)
                    )

                if !viewModel.price.isEmpty && !viewModel.isPriceValid {
                    Text("Precio inválido")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
            }
            .listRowSeparator(.visible)

            Section("Categoría") {
                Picker("Categoría", selection: $viewModel.selectedCategory) {
                    Text("Seleccionar Categoría").tag(nil as CategoryDomain?)
                    ForEach(viewModel.categories, id: \.id) { category in
                        HStack {
                            Circle()
                                .fill(Color(hex: category.color) ?? Color.gray)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                        }
                        .tag(category as CategoryDomain?)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Método de Pago") {
                Picker("Método de Pago", selection: $viewModel.selectedPaymentMethod) {
                    Text("Seleccionar Método de Pago").tag(nil as PaymentMethodDomain?)
                    ForEach(viewModel.paymentMethods, id: \.id) { paymentMethod in
                        HStack {
                            Image(systemName: paymentMethodIcon(for: paymentMethod.type))
                                .foregroundColor(paymentMethodColor(for: paymentMethod.type))
                            Text(paymentMethod.name)
                        }
                        .tag(paymentMethod as PaymentMethodDomain?)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Grupo") {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)

                    Text(group.name)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("(No editable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Nuevo Gasto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    onCancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await saveItemList()
                    }
                }
                .disabled(!viewModel.canSave)
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
        .task {
            // ✅ Clean Architecture: View just passes Domain model to ViewModel
            // ViewModel handles all data fetching
            await viewModel.loadCategories(forGroupId: group.id)
            await viewModel.loadPaymentMethods(forGroupId: group.id)
        }
    }
    
    // MARK: - Actions
    
    private func saveItemList() async {
        guard let category = viewModel.selectedCategory else { return }

        print("🔄 AddItemListView: Creating ItemList...")

        // ✅ Clean Architecture: Pass UUIDs instead of Core Data entities
        if let createdItemList = await viewModel.createItemList(
            description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: viewModel.date,
            categoryId: category.id,
            groupId: group.id,
            paymentMethodId: viewModel.selectedPaymentMethod?.id
        ) {
            // ✅ SUCCESS: ItemList created successfully
            print("✅ AddItemListView: ItemList created: '\(createdItemList.itemListDescription)'")
            print("🔄 AddItemListView: Calling onItemListCreated callback with ItemList...")
            
            // Pass the created ItemListDomain to the callback for incremental cache update
            onItemListCreated(createdItemList)

            print("✅ AddItemListView: Callback executed")
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
        onItemListCreated: { _ in },
        onCancel: { }
    )
}
