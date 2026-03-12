import SwiftUI

/// ✅ Clean Architecture: Works with Domain models only, no Core Data dependencies
struct AddItemListView: View {
    let user: UserDomain
    let group: GroupDomain
    let onItemListCreated: (ItemListDomain) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: Field?
    @State private var showDatePicker = false

    private enum Field { case description, price }

    init(user: UserDomain, group: GroupDomain, onItemListCreated: @escaping (ItemListDomain) -> Void, onCancel: @escaping () -> Void) {
        self.user = user
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: AddItemListViewModel())
    }

    // MARK: - Computed

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = group.currency
        return formatter.currencySymbol
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: viewModel.date)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroPriceSection
                descriptionCard
                dateCard
                if !viewModel.categories.isEmpty {
                    categorySection
                }
                if !viewModel.paymentMethods.isEmpty {
                    paymentMethodSection
                }
                groupBadge
            }
            .padding(AppConstants.UserInterface.padding)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Nuevo Gasto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { onCancel() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { focusedField = nil }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await saveItemList() }
                }
                .disabled(!viewModel.canSave)
                .fontWeight(.semibold)
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
            await viewModel.loadCategories(forGroupId: group.id)
            await viewModel.loadPaymentMethods(forGroupId: group.id)
        }
    }

    // MARK: - Sections

    private var heroPriceSection: some View {
        VStack(spacing: 3) {
            Text(currencySymbol)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            TextField("0,00", text: $viewModel.price)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .price)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.price) { _, _ in
                    viewModel.validateAndCorrectPrice()
                }

            Text("(opcional)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppConstants.UserInterface.padding)
        .padding(.bottom, AppConstants.UserInterface.smallPadding)
        .onTapGesture { focusedField = .price }
    }

    private var descriptionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField("Descripción", text: $viewModel.description)
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

    private var dateCard: some View {
        VStack(spacing: 0) {
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
                        .foregroundStyle(.primary)

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
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categoría")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.categories.sorted { $0.isDefault && !$1.isDefault }) { category in
                        let isSelected = viewModel.selectedCategory?.id == category.id
                        let chipColor = Color(hex: category.color) ?? Color.accentColor
                        Button {
                            withAnimation(AnimationHelper.quickSpring) {
                                viewModel.selectedCategory = category
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(isSelected ? .white : chipColor)
                                Text(category.name)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .foregroundStyle(isSelected ? .white : .primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Método de pago")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.paymentMethods.sorted { $0.isDefault && !$1.isDefault }) { method in
                        let isSelected = viewModel.selectedPaymentMethod?.id == method.id
                        let chipColor = Color(hex: method.color) ?? Color.accentColor
                        Button {
                            withAnimation(AnimationHelper.quickSpring) {
                                viewModel.selectedPaymentMethod = method
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: method.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(isSelected ? .white : chipColor)
                                Text(method.name)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .foregroundStyle(isSelected ? .white : .primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }

    private var groupBadge: some View {
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
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
    let user = UserDomain(id: UUID(), name: "Test User", email: "test@example.com")
    let group = GroupDomain(id: UUID(), name: "Casa", currency: "EUR")
    NavigationStack {
        AddItemListView(
            user: user,
            group: group,
            onItemListCreated: { _ in },
            onCancel: { }
        )
    }
}
