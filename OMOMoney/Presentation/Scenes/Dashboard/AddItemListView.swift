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
    @State private var showCategoryOverflow = false
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

    private var lastUsedCategoryIds: [UUID] {
        UserDefaults.standard
            .string(forKey: "lastUsedCategoryIds_\(group.id.uuidString)")
            .map { $0.components(separatedBy: ",").compactMap { UUID(uuidString: $0) } }
            ?? []
    }

    private var lastUsedNonDefaultPaymentMethodId: UUID? {
        UserDefaults.standard
            .string(forKey: "lastUsedNonDefaultPaymentMethodId_\(group.id.uuidString)")
            .flatMap { UUID(uuidString: $0) }
    }

    private func sortedCategories() -> [CategoryDomain] {
        viewModel.categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    private func sortedPaymentMethods() -> [PaymentMethodDomain] {
        viewModel.paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedNonDefaultPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedNonDefaultPaymentMethodId)
        }
    }

    private func chipRank(_ id: UUID, lastUsed: [UUID]) -> Int {
        lastUsed.firstIndex(of: id) ?? lastUsed.count
    }

    private func chipRank(_ id: UUID, lastUsed: UUID?) -> Int {
        id == lastUsed ? 0 : 1
    }

    private static let gridCategoryLimit = 5

    private var gridCategories: [CategoryDomain] {
        orderedCategories.filter { !$0.isDefault }.prefix(Self.gridCategoryLimit).map { $0 }
    }

    private var overflowCategories: [CategoryDomain] {
        let extra = orderedCategories.filter { !$0.isDefault }.dropFirst(Self.gridCategoryLimit)
        let defaults = orderedCategories.filter { $0.isDefault }
        return Array(extra) + defaults
    }

    private func recordCategoryUsage(_ category: CategoryDomain) {
        var ids = lastUsedCategoryIds
        ids.removeAll { $0 == category.id }
        ids.insert(category.id, at: 0)
        let stored = ids.prefix(Self.gridCategoryLimit).map { $0.uuidString }.joined(separator: ",")
        UserDefaults.standard.set(stored, forKey: "lastUsedCategoryIds_\(group.id.uuidString)")
    }

    private var categoryChipMinHeight: CGFloat {
        showDetails ? 44 : 88
    }

    private var categoryChipCornerRadius: CGFloat {
        showDetails ? 12 : 16
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
        ScrollViewReader { proxy in
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
        .task(id: showDetails) {
            guard showDetails, !viewModel.isEditMode else { return }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                proxy.scrollTo("moreDetailsAnchor", anchor: .bottom)
            }
        }
        .task(id: showDatePicker) {
            guard showDatePicker else { return }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                proxy.scrollTo("datePickerAnchor", anchor: .bottom)
            }
        }
        } // ScrollViewReader
        .scrollDisabled(!showDetails && !viewModel.isEditMode)
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
        .sheet(isPresented: $showCategoryOverflow) {
            categoryOverflowSheet
                .presentationDetents([.height(CGFloat(ceil(Double(overflowCategories.count) / 2)) * 56 + 80)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            async let categories: () = viewModel.loadCategories(forGroupId: group.id, lastUsedCategoryId: lastUsedCategoryIds.first)
            async let paymentMethods: () = viewModel.loadPaymentMethods(forGroupId: group.id, lastUsedPaymentMethodId: lastUsedNonDefaultPaymentMethodId)
            _ = await (categories, paymentMethods)
            orderedCategories = sortedCategories()
            orderedPaymentMethods = sortedPaymentMethods()
            if viewModel.isEditMode {
                showDetails = true
            }
        }
    }

    // MARK: - Hero Amount Input

    private var heroAmountInput: some View {
        HeroAmountInputView(
            text: $viewModel.price,
            currencySymbol: currencySymbol,
            onValidate: viewModel.validateAndCorrectPrice,
            focusedField: $focusedField,
            fieldValue: .price
        )
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
                ForEach(gridCategories) { category in
                    categoryChip(category)
                }

                if !overflowCategories.isEmpty {
                    overflowChip
                }
            }

        }
    }

    @ViewBuilder
    private func categoryChip(_ category: CategoryDomain) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        let chipColor = Color(hex: category.color) ?? Color.accentColor
        Button {
            withAnimation(AnimationHelper.quickSpring) {
                viewModel.selectedCategory = category
                recordCategoryUsage(category)
                showCategoryOverflow = false
            }
        } label: {
            ZStack {
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
                .opacity(showDetails ? 1 : 0)
                .scaleEffect(showDetails ? 1 : 0.85, anchor: .leading)

                VStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : chipColor)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
                .opacity(showDetails ? 0 : 1)
                .scaleEffect(showDetails ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: showDetails ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: categoryChipMinHeight)
            .padding(.horizontal, showDetails ? 14 : 12)
            .padding(.vertical, showDetails ? 12 : 10)
            .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: categoryChipCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: categoryChipCornerRadius)
                    .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showDetails)
        }
        .buttonStyle(.plain)
    }

    private var categoryOverflowSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Más categorías")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(overflowCategories) { category in
                    let isSelected = viewModel.selectedCategory?.id == category.id
                    let chipColor = Color(hex: category.color) ?? Color.accentColor
                    Button {
                        withAnimation(AnimationHelper.quickSpring) {
                            viewModel.selectedCategory = category
                            recordCategoryUsage(category)
                            showCategoryOverflow = false
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
        .padding(AppConstants.UserInterface.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overflowChip: some View {
        let overflowSelected = overflowCategories.first { $0.id == viewModel.selectedCategory?.id }
        let chipColor = overflowSelected.flatMap { Color(hex: $0.color) } ?? Color(.systemGray3)
        let icon = overflowSelected?.icon ?? "ellipsis.circle.fill"
        let label = overflowSelected?.name ?? "Más"
        let isActive = overflowSelected != nil

        return Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                showCategoryOverflow.toggle()
            }
        } label: {
            ZStack {
                // Compacto
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(isActive ? .white : chipColor)
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundStyle(isActive ? .white : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? .white.opacity(0.8) : Color(.tertiaryLabel))
                        .rotationEffect(.degrees(showCategoryOverflow ? 180 : 0))
                }
                .opacity(showDetails ? 1 : 0)
                .scaleEffect(showDetails ? 1 : 0.85, anchor: .leading)

                // Grande
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isActive ? .white : chipColor)
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? .white : .primary)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isActive ? .white.opacity(0.8) : Color(.tertiaryLabel))
                            .rotationEffect(.degrees(showCategoryOverflow ? 180 : 0))
                    }
                }
                .opacity(showDetails ? 0 : 1)
                .scaleEffect(showDetails ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: showDetails ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: categoryChipMinHeight)
            .padding(.horizontal, showDetails ? 14 : 12)
            .padding(.vertical, showDetails ? 12 : 10)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: categoryChipCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: categoryChipCornerRadius)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showDetails)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showCategoryOverflow)
        }
        .buttonStyle(.plain)
    }

    // MARK: - More Details Section

    private var moreDetailsSection: some View {
        VStack(spacing: 16) {
            if !viewModel.isEditMode {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showDetails.toggle()
                    }
                } label: {
                    HStack {
                        Text("Más detalles")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
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

                    Color.clear
                        .frame(height: 1)
                        .id("moreDetailsAnchor")
                }
                .transition(viewModel.isEditMode ? .identity : .opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .animation(viewModel.isEditMode ? nil : .spring(response: 0.45, dampingFraction: 0.82), value: showDetails)
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
                        .frame(maxWidth: .infinity, minHeight: 44)
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
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
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
                    .id("datePickerAnchor")
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
