import SwiftUI

/// ✅ Clean Architecture: Works with Domain models only, no Core Data dependencies
struct AddItemListView: View {
    let user: UserDomain
    let group: GroupDomain
    let onItemListCreated: (ItemListDomain) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case description, price }

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
                    .focused($focusedField, equals: .description)
                    .onChange(of: viewModel.description) { _, newValue in
                        if newValue.count > 30 {
                            viewModel.description = String(newValue.prefix(30))
                        }
                    }

                TextField("Precio (opcional)", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .price)
                    .onChange(of: viewModel.price) { _, _ in
                        viewModel.validateAndCorrectPrice()
                    }
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

                Picker("Categoría", selection: Binding(
                    get: { viewModel.selectedCategory?.id },
                    set: { newId in
                        viewModel.selectedCategory = viewModel.categories.first { $0.id == newId }
                    }
                )) {
                    Text("Seleccionar").tag(nil as UUID?)
                    ForEach(viewModel.categories, id: \.id) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color) ?? .gray)
                            Text(category.name)
                        }
                        .tag(category.id as UUID?)
                    }
                }
                .pickerStyle(.menu)

                Picker("Pago", selection: Binding(
                    get: { viewModel.selectedPaymentMethod?.id },
                    set: { newId in
                        viewModel.selectedPaymentMethod = viewModel.paymentMethods.first { $0.id == newId }
                    }
                )) {
                    Text("Seleccionar").tag(nil as UUID?)
                    ForEach(viewModel.paymentMethods, id: \.id) { paymentMethod in
                        HStack {
                            Image(systemName: paymentMethod.icon)
                                .foregroundColor(Color(hex: paymentMethod.color) ?? .gray)
                            Text(paymentMethod.name)
                        }
                        .tag(paymentMethod.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
            .listRowSeparator(.visible)

            Section("Grupo") {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(group.name)
                        .foregroundColor(.primary)
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

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { focusedField = nil }
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
            await viewModel.loadCategories(forGroupId: group.id)
            await viewModel.loadPaymentMethods(forGroupId: group.id)
        }
    }
    
    // MARK: - Actions
    
    private func saveItemList() async {
        guard let category = viewModel.selectedCategory else { return }

        if let createdItemList = await viewModel.createItemList(
            description: viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: viewModel.date,
            categoryId: category.id,
            groupId: group.id,
            paymentMethodId: viewModel.selectedPaymentMethod?.id
        ) {
            onItemListCreated(createdItemList)
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
