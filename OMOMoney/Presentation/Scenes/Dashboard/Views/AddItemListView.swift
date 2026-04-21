import SwiftUI

struct AddItemListView: View {
    let group: SDGroup
    let onItemListCreated: (SDItemList) -> Void
    let onItemListUpdated: ((SDItemList) -> Void)?
    let onCancel: () -> Void

    @State private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: Field?
    @State private var showDatePicker = false
    @State private var calendarExpanded = false
    @State private var showDetails = false
    @State private var showCategoryOverflow = false
    @State private var showPaymentMethodOverflow = false
    @State private var orderedCategories: [SDCategory] = []
    @State private var orderedPaymentMethods: [SDPaymentMethod] = []

    private enum Field { case description, price }

    init(
        group: SDGroup,
        itemListToEdit: SDItemList? = nil,
        initialDate: Date? = nil,
        onItemListCreated: @escaping (SDItemList) -> Void,
        onItemListUpdated: ((SDItemList) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onItemListUpdated = onItemListUpdated
        self.onCancel = onCancel
        self._viewModel = State(wrappedValue: AddItemListViewModel(itemListToEdit: itemListToEdit, initialDate: initialDate))
    }

    // MARK: - Computed

    private var lastUsedCategoryIds: [UUID] {
        UserDefaults.standard
            .string(forKey: "lastUsedCategoryIds_\(group.id.uuidString)")
            .map { $0.components(separatedBy: ",").compactMap { UUID(uuidString: $0) } }
            ?? []
    }

    private var lastUsedPaymentMethodId: UUID? {
        UserDefaults.standard
            .string(forKey: "lastUsedPaymentMethodId_\(group.id.uuidString)")
            .flatMap { UUID(uuidString: $0) }
    }

    private func sortedCategories() -> [SDCategory] {
        viewModel.categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    private func sortedPaymentMethods() -> [SDPaymentMethod] {
        viewModel.paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedPaymentMethodId)
        }
    }

    private func chipRank(_ id: UUID, lastUsed: [UUID]) -> Int {
        lastUsed.firstIndex(of: id) ?? lastUsed.count
    }

    private func chipRank(_ id: UUID, lastUsed: UUID?) -> Int {
        id == lastUsed ? 0 : 1
    }

    private static let gridCategoryLimit = 3
    private static let gridPaymentMethodLimit = 3

    private var gridCategories: [SDCategory] {
        orderedCategories.prefix(Self.gridCategoryLimit).map { $0 }
    }

    private var overflowCategories: [SDCategory] {
        Array(orderedCategories.dropFirst(Self.gridCategoryLimit))
    }

    private var gridPaymentMethods: [SDPaymentMethod] {
        orderedPaymentMethods.prefix(Self.gridPaymentMethodLimit).map { $0 }
    }

    private var overflowPaymentMethods: [SDPaymentMethod] {
        Array(orderedPaymentMethods.dropFirst(Self.gridPaymentMethodLimit))
    }

    private func recordCategoryUsage(_ category: SDCategory) {
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

    private var descriptionPlaceholder: String {
        if let category = viewModel.selectedCategory {
            return "Concepto (ej. \(category.name))"
        }
        return "Concepto"
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 20) {
                topCard
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
        .navigationTitle(viewModel.isEditMode ? "Editar" : "Nuevo Registro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { onCancel() } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if viewModel.canSave {
                        Task { await saveItemList() }
                    } else {
                        viewModel.showValidationToast()
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
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
        .sheet(isPresented: $showPaymentMethodOverflow) {
            paymentMethodOverflowSheet
                .presentationDetents([.height(CGFloat(ceil(Double(overflowPaymentMethods.count) / 2)) * 56 + 80)])
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
            async let paymentMethods: () = viewModel.loadPaymentMethods(forGroupId: group.id, lastUsedPaymentMethodId: lastUsedPaymentMethodId)
            _ = await (categories, paymentMethods)
            orderedCategories = sortedCategories()
            orderedPaymentMethods = sortedPaymentMethods()
            if viewModel.isEditMode {
                showDetails = true
            }
        }
        .toast($viewModel.toast)
    }

    // MARK: - Top Card (Concept + Amount)

    private var topCard: some View {
        VStack(spacing: 0) {
            // Hero amount input is a dashboard quick-add shortcut only — hidden in edit mode
            if !viewModel.isEditMode {
                HeroAmountInputView(
                    text: $viewModel.price,
                    currencySymbol: currencySymbol,
                    onValidate: viewModel.validateAndCorrectPrice,
                    focusedField: $focusedField,
                    fieldValue: .price,
                    embedded: true,
                    onPaste: viewModel.pastePrice
                )

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1.5)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.top, viewModel.isEditMode ? 2 : 1)

                TextField(descriptionPlaceholder, text: $viewModel.description, axis: .vertical)
                    .font(viewModel.isEditMode ? .body : .subheadline)
                    .foregroundStyle(viewModel.isEditMode ? .primary : .secondary)
                    .focused($focusedField, equals: .description)

                if !viewModel.description.isEmpty {
                    Button { viewModel.description = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .animation(AnimationHelper.quickEase, value: viewModel.description.isEmpty)
                }
            }
            .padding(viewModel.isEditMode ? AppConstants.UserInterface.largePadding : AppConstants.UserInterface.padding)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
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
    private func categoryChip(_ category: SDCategory) -> some View {
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
                    dateCard

                    groupCard

                    if !orderedPaymentMethods.isEmpty {
                        paymentMethodGridSection
                    }

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
        LimitedTextField(
            icon: "text.alignleft",
            placeholder: descriptionPlaceholder,
            text: $viewModel.description,
            focusedField: $focusedField,
            fieldValue: .description
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
                ForEach(gridPaymentMethods) { method in
                    paymentMethodChip(method)
                }
                if !overflowPaymentMethods.isEmpty {
                    paymentMethodOverflowChip
                }
            }
        }
    }

    private func paymentMethodChip(_ method: SDPaymentMethod) -> some View {
        let isSelected = viewModel.selectedPaymentMethod?.id == method.id
        let chipColor = paymentMethodColor(method.type)
        return Button {
            withAnimation(AnimationHelper.quickSpring) {
                if viewModel.selectedPaymentMethod?.id == method.id {
                    viewModel.selectedPaymentMethod = nil
                } else {
                    viewModel.selectedPaymentMethod = method
                    UserDefaults.standard.set(method.id.uuidString, forKey: "lastUsedPaymentMethodId_\(group.id.uuidString)")
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: paymentMethodIcon(method))
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

    private var paymentMethodOverflowChip: some View {
        let overflowSelected = overflowPaymentMethods.first { $0.id == viewModel.selectedPaymentMethod?.id }
        let chipColor = overflowSelected.map { paymentMethodColor($0.type) } ?? Color(.systemGray3)
        let icon = overflowSelected.map { paymentMethodIcon($0) } ?? "ellipsis.circle.fill"
        let label = overflowSelected?.name ?? "Más"
        let isActive = overflowSelected != nil

        return Button {
            withAnimation(AnimationHelper.quickSpring) {
                showPaymentMethodOverflow.toggle()
            }
        } label: {
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
                    .rotationEffect(.degrees(showPaymentMethodOverflow ? 180 : 0))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(AnimationHelper.quickSpring, value: showPaymentMethodOverflow)
        }
        .buttonStyle(.plain)
    }

    private var paymentMethodOverflowSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Más métodos de pago")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(overflowPaymentMethods) { method in
                    let isSelected = viewModel.selectedPaymentMethod?.id == method.id
                    let chipColor = paymentMethodColor(method.type)
                    Button {
                        withAnimation(AnimationHelper.quickSpring) {
                            if viewModel.selectedPaymentMethod?.id == method.id {
                                viewModel.selectedPaymentMethod = nil
                            } else {
                                viewModel.selectedPaymentMethod = method
                                UserDefaults.standard.set(method.id.uuidString, forKey: "lastUsedPaymentMethodId_\(group.id.uuidString)")
                            }
                            showPaymentMethodOverflow = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: paymentMethodIcon(method))
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
        .padding(AppConstants.UserInterface.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Date Card

    private var dateCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    guard showDatePicker else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        calendarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fecha")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(showDatePicker ? viewModel.formattedDate : "Hoy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if showDatePicker {
                            Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Toggle("", isOn: $showDatePicker)
                    .labelsHidden()
                    .onChange(of: showDatePicker) { _, on in
                        focusedField = nil
                        if on {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                calendarExpanded = true
                            }
                        } else {
                            viewModel.date = Date()
                            calendarExpanded = false
                        }
                    }
            }
            .padding(AppConstants.UserInterface.padding)

            if showDatePicker && calendarExpanded {
                Divider()
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, AppConstants.UserInterface.smallPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .id("datePickerAnchor")
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: calendarExpanded)
    }

    // MARK: - Group Card

    private var groupCard: some View {
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

    // MARK: - Payment Method Helpers

    private func paymentMethodColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    private func paymentMethodIcon(_ method: SDPaymentMethod) -> String {
        method.icon.isEmpty ? defaultIcon(for: method.type) : method.icon
    }

    private func defaultIcon(for type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        case "card_credit":   return "creditcard.fill"
        default:              return "creditcard.fill"
        }
    }

    // MARK: - Actions

    private func saveItemList() async {
        let finalDescription = viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (viewModel.selectedCategory?.name ?? "Concepto")
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
                categoryId: viewModel.selectedCategory?.id ?? UUID(),
                groupId: group.id,
                paymentMethodId: viewModel.selectedPaymentMethod?.id
            ) {
                onItemListCreated(created)
            }
        }
    }
}


#Preview {
    let group = SDGroup.mock(name: "Casa", currency: "EUR")
    NavigationStack {
        AddItemListView(
            group: group,
            onItemListCreated: { _ in },
            onCancel: { }
        )
    }
}
