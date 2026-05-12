import SwiftUI

struct AddItemListView: View {
    let group: SDGroup
    let onItemListCreated: (SDItemList) -> Void
    let onItemListUpdated: ((SDItemList) -> Void)?
    let onCancel: () -> Void

    @State private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: AddItemListField?
    @State private var showDatePicker = false
    @State private var calendarExpanded = false
    @State private var suppressCalendarExpand = false
    @State private var showDetails = false
    @State private var showCategoryOverflow = false
    @State private var showPaymentMethodOverflow = false
    @State private var scrollToPaymentMethods = false
    @State private var orderedCategories: [SDCategory] = []
    @State private var orderedPaymentMethods: [SDPaymentMethod] = []

    init(
        group: SDGroup,
        itemListToEdit: SDItemList? = nil,
        initialDate: Date? = nil,
        preferredCategoryId: UUID? = nil,
        onItemListCreated: @escaping (SDItemList) -> Void,
        onItemListUpdated: ((SDItemList) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onItemListUpdated = onItemListUpdated
        self.onCancel = onCancel
        self._viewModel = State(
            wrappedValue: AddItemListViewModel(
                itemListToEdit: itemListToEdit,
                initialDate: initialDate,
                preferredCategoryId: preferredCategoryId
            )
        )
    }

    // MARK: - Computed

    private var activeGroup: SDGroup { viewModel.selectedGroup ?? group }

    private static let gridCategoryLimit = 3
    private static let gridPaymentMethodLimit = 3

    private var gridCategories: [SDCategory] {
        orderedCategories.prefix(Self.gridCategoryLimit).map { $0 }
    }

    private var overflowCategories: [SDCategory] {
        Array(orderedCategories.dropFirst(Self.gridCategoryLimit))
    }

    private var displayedCategories: [SDCategory] {
        showCategoryOverflow ? orderedCategories : gridCategories
    }

    private var gridPaymentMethods: [SDPaymentMethod] {
        orderedPaymentMethods.prefix(Self.gridPaymentMethodLimit).map { $0 }
    }

    private var overflowPaymentMethods: [SDPaymentMethod] {
        Array(orderedPaymentMethods.dropFirst(Self.gridPaymentMethodLimit))
    }

    private var displayedPaymentMethods: [SDPaymentMethod] {
        showPaymentMethodOverflow ? orderedPaymentMethods : gridPaymentMethods
    }

    private var categoryChipMinHeight: CGFloat {
        (showDetails || showCategoryOverflow) ? 44 : 88
    }

    private var categoryChipCornerRadius: CGFloat {
        (showDetails || showCategoryOverflow) ? 12 : 16
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = activeGroup.currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var descriptionPlaceholder: String {
        if let concept = viewModel.lastUsedConcept {
            return concept
        }
        if let category = viewModel.selectedCategory {
            return "\(LocalizationKey.Entry.concept.localized) (ej. \(category.name))"
        }
        return LocalizationKey.Entry.concept.localized
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

        .onChange(of: scrollToPaymentMethods) { _, fire in
            guard fire else { return }
            scrollToPaymentMethods = false
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    proxy.scrollTo("paymentMethodAnchor", anchor: .top)
                }
            }
        }

        } // ScrollViewReader
        .scrollDisabled(!showDetails && !viewModel.isEditMode && !showCategoryOverflow && !showPaymentMethodOverflow)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.isEditMode ? LocalizationKey.Entry.edit.localized : LocalizationKey.Entry.newEntry.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { onCancel() } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                PrimaryToolbarCheckButton {
                    if viewModel.canSave {
                        Task { await saveItemList() }
                    } else {
                        viewModel.showValidationToast()
                    }
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    moveFocusBackward()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveFocusBackward)

                Button {
                    moveFocusForward()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveFocusForward)

                Spacer()

                Button(LocalizationKey.General.done.localized) { focusedField = nil }
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
            await viewModel.loadGroups()
            if viewModel.selectedGroup == nil { viewModel.selectedGroup = group }
            let activeGroupID = activeGroup.id
            await viewModel.loadUsageMemory(forGroupId: activeGroupID)
            let lastUsedCategoryID = viewModel.lastUsedCategoryIds.first
            let lastUsedPaymentMethodID = viewModel.lastUsedPaymentMethodId
            async let categories: () = viewModel.loadCategories(forGroupId: activeGroupID, lastUsedCategoryId: lastUsedCategoryID)
            async let paymentMethods: () = viewModel.loadPaymentMethods(forGroupId: activeGroupID, lastUsedPaymentMethodId: lastUsedPaymentMethodID)
            _ = await (categories, paymentMethods)
            orderedCategories = viewModel.orderedCategoriesByUsage()
            orderedPaymentMethods = viewModel.orderedPaymentMethodsByUsage()
            if viewModel.isEditMode {
                showDetails = true
                if !Calendar.current.isDateInToday(viewModel.date) {
                    suppressCalendarExpand = true
                    showDatePicker = true
                }
            }
        }
        .onChange(of: viewModel.selectedGroup?.id) { oldValue, _ in
            guard oldValue != nil else { return }
            let previousCategoryName = viewModel.selectedCategory?.name
            let previousPaymentMethodName = viewModel.selectedPaymentMethod?.name
            viewModel.selectedCategory = nil
            viewModel.selectedPaymentMethod = nil
            Task {
                let activeGroupID = activeGroup.id
                await viewModel.loadUsageMemory(forGroupId: activeGroupID)
                let lastUsedCategoryID = viewModel.lastUsedCategoryIds.first
                let lastUsedPaymentMethodID = viewModel.lastUsedPaymentMethodId
                async let categories: () = viewModel.loadCategories(forGroupId: activeGroupID, lastUsedCategoryId: lastUsedCategoryID)
                async let paymentMethods: () = viewModel.loadPaymentMethods(forGroupId: activeGroupID, lastUsedPaymentMethodId: lastUsedPaymentMethodID)
                _ = await (categories, paymentMethods)
                orderedCategories = viewModel.orderedCategoriesByUsage()
                orderedPaymentMethods = viewModel.orderedPaymentMethodsByUsage()
                if let name = previousCategoryName {
                    viewModel.selectedCategory = viewModel.categories.first {
                        $0.name.lowercased() == name.lowercased()
                    } ?? viewModel.selectedCategory
                }
                if let name = previousPaymentMethodName {
                    viewModel.selectedPaymentMethod = viewModel.paymentMethods.first {
                        $0.name.lowercased() == name.lowercased()
                    } ?? viewModel.selectedPaymentMethod
                }
            }
        }
        .toast($viewModel.toast)
        .onChange(of: viewModel.description) { viewModel.updateConceptAssists() }
        .onChange(of: viewModel.price) { viewModel.updateSuggestions() }
        .onChange(of: viewModel.selectedCategory) { viewModel.updateConceptAssists() }
        .onChange(of: focusedField) { _, _ in viewModel.updateSuggestions() }
        .animation(AnimationHelper.quickEase, value: focusedField == .description)
    }

    private var canMoveFocusBackward: Bool {
        switch focusedField {
        case .description:
            return !viewModel.isEditMode
        default:
            return false
        }
    }

    private var canMoveFocusForward: Bool {
        switch focusedField {
        case .price:
            return true
        default:
            return false
        }
    }

    private func moveFocusBackward() {
        switch focusedField {
        case .description:
            guard !viewModel.isEditMode else { return }
            focusedField = .price
        default:
            break
        }
    }

    private func moveFocusForward() {
        switch focusedField {
        case .price:
            focusedField = .description
        default:
            break
        }
    }

    // MARK: - Top Card (Concept + Amount)

    private var topCard: some View {
        AddItemListTopCard(
            isEditMode: viewModel.isEditMode,
            price: $viewModel.price,
            currencySymbol: currencySymbol,
            descriptionPlaceholder: descriptionPlaceholder,
            description: $viewModel.description,
            suggestions: viewModel.suggestions,
            focusedField: $focusedField,
            onValidate: viewModel.validateAndCorrectPrice,
            onPaste: viewModel.pastePrice,
            onSuggestionSelected: { viewModel.applySuggestion($0, forGroupId: activeGroup.id) }
        )
    }

    // MARK: - Category Grid

    private var categoryGridSection: some View {
        AddItemListCategorySection(
            displayedCategories: displayedCategories,
            overflowCategories: overflowCategories,
            showOverflow: $showCategoryOverflow,
            compact: showDetails || showCategoryOverflow,
            selectedCategoryID: viewModel.selectedCategory?.id,
            chipMinHeight: categoryChipMinHeight,
            chipCornerRadius: categoryChipCornerRadius
        ) { category in
            withAnimation(AnimationHelper.quickSpring) {
                viewModel.selectedCategory = category
                viewModel.recordCategoryUsage(category, forGroupId: activeGroup.id)
                showCategoryOverflow = false
            }
        }
    }

    // MARK: - More Details Section

    private var moreDetailsSection: some View {
        AddItemListMoreDetailsSection(
            isEditMode: viewModel.isEditMode,
            showDetails: $showDetails,
            onCollapse: {
                showDatePicker = false
                calendarExpanded = false
            }
        ) {
            dateCard
            groupCard

            if !orderedPaymentMethods.isEmpty {
                paymentMethodGridSection
            }

            Color.clear
                .frame(height: 1)
                .id("moreDetailsAnchor")
        }
    }

    // MARK: - Payment Method Grid

    private var paymentMethodGridSection: some View {
        AddItemListPaymentMethodSection(
            displayedPaymentMethods: displayedPaymentMethods,
            overflowPaymentMethods: overflowPaymentMethods,
            showOverflow: $showPaymentMethodOverflow,
            selectedPaymentMethodID: viewModel.selectedPaymentMethod?.id,
            colorForType: paymentMethodColor,
            iconForMethod: paymentMethodIcon,
            onSelect: { method in
                withAnimation(AnimationHelper.quickSpring) {
                    viewModel.selectedPaymentMethod = method
                    viewModel.recordPaymentMethodUsage(method, forGroupId: activeGroup.id)
                    showPaymentMethodOverflow = false
                    scrollToPaymentMethods = true
                }
            },
            onToggleOffSelected: {
                withAnimation(AnimationHelper.quickSpring) {
                    viewModel.deselectPaymentMethodManually()
                    showPaymentMethodOverflow = false
                    scrollToPaymentMethods = true
                }
            },
            onCollapseOverflow: { scrollToPaymentMethods = true }
        )
    }

    // MARK: - Date Card

    private var dateCard: some View {
        AddItemListDateCard(
            showDatePicker: $showDatePicker,
            calendarExpanded: $calendarExpanded,
            date: $viewModel.date,
            formattedDate: viewModel.formattedDate,
            focusedField: $focusedField
        ) { on in
            if on {
                if suppressCalendarExpand {
                    suppressCalendarExpand = false
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        calendarExpanded = true
                    }
                }
            } else {
                viewModel.date = Date()
                calendarExpanded = false
            }
        }
    }

    // MARK: - Group Card

    private var groupCard: some View {
        AddItemListGroupCard(
            activeGroup: activeGroup,
            availableGroups: viewModel.availableGroups,
            onSelect: { viewModel.selectedGroup = $0 }
        )
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
        let finalDescription = viewModel.resolvedDescriptionForSave()

        if viewModel.isEditMode {
            if let updated = await viewModel.updateItemList(groupId: activeGroup.id) {
                onItemListUpdated?(updated)
            }
        } else {
            if let created = await viewModel.createItemList(
                description: finalDescription,
                date: viewModel.date,
                categoryId: viewModel.selectedCategory?.id ?? UUID(),
                groupId: activeGroup.id,
                paymentMethodId: viewModel.selectedPaymentMethod?.id
            ) {
                if let category = viewModel.selectedCategory {
                    viewModel.recordCategoryUsage(category, forGroupId: activeGroup.id)
                }
                if let paymentMethod = viewModel.selectedPaymentMethod {
                    viewModel.recordPaymentMethodUsage(paymentMethod, forGroupId: activeGroup.id)
                }
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
