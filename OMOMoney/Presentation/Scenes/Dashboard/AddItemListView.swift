import SwiftUI

/// ✅ Clean Architecture: Works with Domain models only, no Core Data dependencies
struct AddItemListView: View {
    let group: GroupDomain
    let onItemListCreated: (ItemListDomain) -> Void
    let onItemListUpdated: ((ItemListDomain) -> Void)?
    let onCancel: () -> Void

    @StateObject private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: Field?
    @State private var showDatePicker = false
    @State private var showDetails = false
    @State private var orderedCategories: [CategoryDomain] = []
    @State private var orderedPaymentMethods: [PaymentMethodDomain] = []

    private enum Field { case description, price }

    init(
        group: GroupDomain,
        itemListToEdit: ItemListDomain? = nil,
        onItemListCreated: @escaping (ItemListDomain) -> Void,
        onItemListUpdated: ((ItemListDomain) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onItemListUpdated = onItemListUpdated
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: AddItemListViewModel(itemListToEdit: itemListToEdit))
    }

    // MARK: - Computed

    private var lastUsedNonDefaultCategoryId: UUID? {
        UserDefaults.standard
            .string(forKey: "lastUsedNonDefaultCategoryId_\(group.id.uuidString)")
            .flatMap { UUID(uuidString: $0) }
    }

    private var lastUsedNonDefaultPaymentMethodId: UUID? {
        UserDefaults.standard
            .string(forKey: "lastUsedNonDefaultPaymentMethodId_\(group.id.uuidString)")
            .flatMap { UUID(uuidString: $0) }
    }

    private func sortedCategories() -> [CategoryDomain] {
        viewModel.categories.sorted {
            chipRank($0.id, lastUsed: lastUsedNonDefaultCategoryId) <
            chipRank($1.id, lastUsed: lastUsedNonDefaultCategoryId)
        }
    }

    private func sortedPaymentMethods() -> [PaymentMethodDomain] {
        viewModel.paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedNonDefaultPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedNonDefaultPaymentMethodId)
        }
    }

    private func chipRank(_ id: UUID, lastUsed: UUID?) -> Int {
        id == lastUsed ? 0 : 1
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = group.currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: viewModel.date)
    }

    private var descriptionPlaceholder: String {
        viewModel.selectedCategory?.name ?? "Descripción"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !viewModel.isEditMode {
                    heroAmountInput
                }
                if !orderedCategories.isEmpty {
                    categoryGridSection
                }
                moreDetailsSection
            }
            .padding(AppConstants.UserInterface.padding)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.isEditMode ? "Editar Registro" : "Nuevo Registro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await saveItemList() }
                }
                .disabled(!viewModel.canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { focusedField = nil }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadCategories(forGroupId: group.id, lastUsedCategoryId: lastUsedNonDefaultCategoryId)
            await viewModel.loadPaymentMethods(forGroupId: group.id, lastUsedPaymentMethodId: lastUsedNonDefaultPaymentMethodId)
            orderedCategories = sortedCategories()
            orderedPaymentMethods = sortedPaymentMethods()
            if viewModel.isEditMode {
                showDetails = true
            } else {
                focusedField = .price
            }
        }
    }

    // MARK: - Hero Amount Input

    private var heroAmountInput: some View {
        VStack(spacing: 6) {
            if viewModel.price.isEmpty {
                Text("¿Cuánto has gastado?")
                    .font(.subheadline)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .transition(.opacity)
            }

            // HStack centra número + cursor como unidad; TextField invisible como overlay
            HStack(alignment: .center, spacing: 3) {
                Text(viewModel.price.isEmpty ? "0,00" : viewModel.price)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.price.isEmpty ? Color(.tertiaryLabel) : .primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: viewModel.price)

                if focusedField == .price {
                    BlinkingCursor()
                        .foregroundStyle(.primary)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: focusedField == .price)
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(
                TextField("", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .price)
                    .opacity(0)
                    .onChange(of: viewModel.price) { _, _ in
                        viewModel.validateAndCorrectPrice()
                    }
            )

            Text(currencySymbol)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.price.isEmpty)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                .stroke(focusedField == .price ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                .animation(AnimationHelper.formFocus, value: focusedField == .price)
        )
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .price }
    }

    // MARK: - Category Grid

    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categoría")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(orderedCategories) { category in
                    let isSelected = viewModel.selectedCategory?.id == category.id
                    let chipColor = Color(hex: category.color) ?? Color.accentColor
                    Button {
                        withAnimation(AnimationHelper.quickSpring) {
                            viewModel.selectedCategory = category
                            if !category.isDefault {
                                UserDefaults.standard.set(category.id.uuidString, forKey: "lastUsedNonDefaultCategoryId_\(group.id.uuidString)")
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.subheadline)
                                .foregroundStyle(isSelected ? .white : chipColor)
                            Text(category.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .white : .primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - More Details Section

    private var moreDetailsSection: some View {
        VStack(spacing: 16) {
            if !viewModel.isEditMode {
                Button {
                    withAnimation(AnimationHelper.smoothSpring) {
                        showDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Más detalles")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }

            if viewModel.isEditMode || showDetails {
                VStack(spacing: 16) {
                    descriptionCard

                    if !orderedPaymentMethods.isEmpty {
                        paymentMethodGridSection
                    }

                    dateGroupCard
                }
                .transition(viewModel.isEditMode ? .identity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField(descriptionPlaceholder, text: $viewModel.description)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .fontWeight(.semibold)
                .focused($focusedField, equals: .description)
                .onChange(of: viewModel.description) { _, newValue in
                    if newValue.count > 20 {
                        viewModel.description = String(newValue.prefix(20))
                    }
                }

            Text("\(viewModel.description.count)/20")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
                .animation(AnimationHelper.quickEase, value: viewModel.description.count)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                .stroke(focusedField == .description ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                .animation(AnimationHelper.formFocus, value: focusedField == .description)
        )
    }

    // MARK: - Payment Method Grid

    private var paymentMethodGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Método de pago")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(orderedPaymentMethods) { method in
                    let isSelected = viewModel.selectedPaymentMethod?.id == method.id
                    let chipColor = Color(hex: method.color) ?? Color.accentColor
                    Button {
                        withAnimation(AnimationHelper.quickSpring) {
                            viewModel.selectedPaymentMethod = method
                            if !method.isDefault {
                                UserDefaults.standard.set(method.id.uuidString, forKey: "lastUsedNonDefaultPaymentMethodId_\(group.id.uuidString)")
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: method.icon)
                                .font(.subheadline)
                                .foregroundStyle(isSelected ? .white : chipColor)
                            Text(method.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .white : .primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Date + Group Card

    private var dateGroupCard: some View {
        VStack(spacing: 0) {
            // Date row
            Button {
                focusedField = nil
                withAnimation(AnimationHelper.smoothSpring) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20)
                    Text("Fecha")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formattedDate)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(AppConstants.UserInterface.padding)
            }
            .buttonStyle(.plain)

            if showDatePicker {
                Divider()
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, AppConstants.UserInterface.smallPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.horizontal, AppConstants.UserInterface.padding)

            // Group row
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
                Text("Grupo")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(group.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
    }

    // MARK: - Actions

    private func saveItemList() async {
        guard let category = viewModel.selectedCategory else { return }
        let finalDescription = viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? category.name
            : viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if viewModel.isEditMode {
            if viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.description = finalDescription
            }
            if let updated = await viewModel.updateItemList(groupId: group.id) {
                onItemListUpdated?(updated)
            }
        } else {
            if let created = await viewModel.createItemList(
                description: finalDescription,
                date: viewModel.date,
                categoryId: category.id,
                groupId: group.id,
                paymentMethodId: viewModel.selectedPaymentMethod?.id
            ) {
                onItemListCreated(created)
            }
        }
    }
}

private struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .frame(width: 2.5, height: 46)
            .cornerRadius(1.5)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}

#Preview {
    let group = GroupDomain(id: UUID(), name: "Casa", currency: "EUR")
    NavigationStack {
        AddItemListView(
            group: group,
            onItemListCreated: { _ in },
            onCancel: { }
        )
    }
}
