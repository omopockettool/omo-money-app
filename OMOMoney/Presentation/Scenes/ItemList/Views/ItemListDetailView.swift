import SwiftUI

struct ItemListDetailView: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let onItemListUpdated: ((SDItemList) -> Void)?

    @State private var viewModel: ItemListDetailViewModel
    @State private var sheetMode: ItemSheetMode?
    @State private var hasLoadedInitialData = false

    @State private var heroIsSuccess: Bool = false

    enum ItemSheetMode: Identifiable {
        case create
        case edit(SDItem)
        case editRegistry

        var id: String {
            switch self {
            case .create:       return "create"
            case .edit(let i):  return "edit-\(i.id)"
            case .editRegistry: return "editRegistry"
            }
        }
    }

    let onPaidStatusChanged: (() -> Void)?

    init(
        itemList: SDItemList,
        currencyCode: String = "EUR",
        group: SDGroup,
        onItemListUpdated: ((SDItemList) -> Void)? = nil,
        onPaidStatusChanged: (() -> Void)? = nil
    ) {
        self.itemList = itemList
        self.currencyCode = currencyCode
        self.group = group
        self.onItemListUpdated = onItemListUpdated
        self.onPaidStatusChanged = onPaidStatusChanged

        let container = AppDIContainer.shared
        self._viewModel = State(wrappedValue: ItemListDetailViewModel(
            itemList: itemList,
            currencyCode: currencyCode,
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            createItemUseCase: container.makeCreateItemUseCase(),
            updateItemUseCase: container.makeUpdateItemUseCase(),
            deleteItemUseCase: container.makeDeleteItemUseCase(),
            toggleItemPaidUseCase: container.makeToggleItemPaidUseCase()
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Cargando artículos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                mainContentView
            }
        }
        .navigationTitle(itemList.itemListDescription)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Editar Registro", systemImage: "pencil") {
                        sheetMode = .editRegistry
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            guard !hasLoadedInitialData else {
                Task { await viewModel.loadItems() }
                return
            }
            hasLoadedInitialData = true
            Task { await viewModel.loadItems() }
        }
        .sheet(item: $sheetMode) { mode in
            let container = AppDIContainer.shared
            switch mode {
            case .create:
                AddItemView(
                    itemListId: itemList.id,
                    itemToEdit: nil,
                    itemListDescription: itemList.itemListDescription,
                    currencyCode: currencyCode,
                    onItemSaved: { item in
                        Task { await viewModel.addItem(item) }
                        withAnimation(AnimationHelper.smoothSpring) { heroIsSuccess = true }
                        Task {
                            try? await Task.sleep(for: .milliseconds(900))
                            withAnimation(AnimationHelper.smoothSpring) { heroIsSuccess = false }
                        }
                    },
                    createItemUseCase: container.makeCreateItemUseCase(),
                    updateItemUseCase: container.makeUpdateItemUseCase()
                )
            case .edit(let item):
                AddItemView(
                    itemListId: itemList.id,
                    itemToEdit: item,
                    itemListDescription: itemList.itemListDescription,
                    currencyCode: currencyCode,
                    onItemSaved: { item in Task { await viewModel.updateItem(item) } },
                    createItemUseCase: container.makeCreateItemUseCase(),
                    updateItemUseCase: container.makeUpdateItemUseCase()
                )
            case .editRegistry:
                NavigationStack {
                    AddItemListView(
                        group: group,
                        itemListToEdit: itemList,
                        onItemListCreated: { _ in },
                        onItemListUpdated: { updated in
                            onItemListUpdated?(updated)
                            sheetMode = nil
                        },
                        onCancel: { sheetMode = nil }
                    )
                }
            }
        }
    }

    // MARK: - Computed

    private var categoryColor: Color {
        Color(hex: itemList.category?.color ?? "") ?? .accentColor
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 0) {
            itemsList
            heroCard
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        TotalSpentCardView(
            label: itemList.itemListDescription,
            totalAmount: viewModel.getFormattedTotal(),
            onAddExpense: { sheetMode = .create },
            isSuccess: heroIsSuccess
        ) {
            heroMetaRow
        }
    }

    private var heroMetaRow: some View {
        HStack(spacing: 10) {
            if let category = itemList.category {
                let color = Color(hex: category.color) ?? .accentColor
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .foregroundStyle(color)
                    Text(category.name)
                        .foregroundStyle(color)
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            if let pm = itemList.paymentMethod {
                let color = pmColor(pm.type)
                HStack(spacing: 4) {
                    Image(systemName: pm.icon.isEmpty ? pmDefaultIcon(pm.type) : pm.icon)
                        .foregroundStyle(color)
                    Text(pm.name)
                        .foregroundStyle(color)
                }
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .padding(.top, 2)
    }

    private func pmColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    // MARK: - Items List (scrollable)

    private var itemsList: some View {
        List {
            if viewModel.items.isEmpty {
                emptyStateRow
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    ItemRowView(
                        item: item,
                        formattedAmount: viewModel.getFormattedAmount(item),
                        currencyCode: currencyCode,
                        onTap: { sheetMode = .edit(item) },
                        onTogglePaid: {
                            Task {
                                await viewModel.toggleItemPaid(item)
                                onPaidStatusChanged?()
                            }
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteItem(item, at: index) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.2), value: viewModel.items.count)
        .refreshable { await viewModel.loadItems() }
    }

    // MARK: - Add Item Button

    private var addItemButton: some View {
        Button { sheetMode = .create } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
                Text("Añadir artículo")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(PressHapticButtonStyle())
    }

    // MARK: - Empty State

    private var emptyStateRow: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "sparkles.2")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Nada por aquí...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pulsa el + para agregar un artículo")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }

    private func pmDefaultIcon(_ type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        default:              return "creditcard.fill"
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") {
                Task { await viewModel.loadItems() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Item Row View

struct ItemRowView: View {
    let item: SDItem
    let formattedAmount: String
    let currencyCode: String
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    private var showsBreakdown: Bool { item.quantity > 1 }
    private var formattedUnitPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: NSNumber(value: item.amount)) ?? "\(item.amount)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onTogglePaid) {
                    Image(systemName: item.isPaid ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.isPaid ? Color.green : Color(.systemGray3))
                }
                .buttonStyle(PressHapticButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemDescription)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if showsBreakdown {
                        Text("\(formattedUnitPrice) × \(item.quantity) uds.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add/Edit Item View

struct AddItemView: View {
    let onItemSaved: (SDItem) -> Void
    let currencyCode: String
    let itemListDescription: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddItemViewModel
    @FocusState private var focusedField: Field?
    @State private var displayedSubtotal: String = ""
    @State private var subtotalIsDecreasing: Bool = false
    private enum Field { case description, amount, quantity }

    init(
        itemListId: UUID,
        itemToEdit: SDItem? = nil,
        itemListDescription: String,
        currencyCode: String = "EUR",
        onItemSaved: @escaping (SDItem) -> Void,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.onItemSaved = onItemSaved
        self.currencyCode = currencyCode
        self.itemListDescription = itemListDescription
        self._viewModel = State(wrappedValue: AddItemViewModel(
            itemListId: itemListId,
            itemToEdit: itemToEdit,
            itemListDescription: itemListDescription,
            createItemUseCase: createItemUseCase,
            updateItemUseCase: updateItemUseCase
        ))
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var quantityValue: Int { Int(viewModel.quantity) ?? 1 }

    private var subtotalAmount: String {
        let normalized = viewModel.amount.replacingOccurrences(of: ",", with: ".")
        guard let price = Decimal(string: normalized), price > 0, quantityValue > 1 else { return "" }
        let total = price * Decimal(quantityValue)
        return String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue) + " " + currencySymbol
    }

    private var subtotalFormula: String {
        guard quantityValue > 1 else { return "" }
        return "\(viewModel.amount) \(currencySymbol) × \(quantityValue) uds."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroAmountInput
                    descriptionCard
                    quantityStepper
                    if viewModel.showsTotalPreview { subtotalCard }
                }
                .padding(AppConstants.UserInterface.padding)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditMode ? "Editar Artículo" : "Nuevo Artículo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if let item = await viewModel.saveItem() {
                                onItemSaved(item)
                                dismiss()
                            }
                        }
                    } label: { Image(systemName: "checkmark") }
                    .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focusedField = nil }
                }
            }
        }
    }

    private var heroAmountInput: some View {
        HeroAmountInputView(
            text: $viewModel.amount,
            currencySymbol: currencySymbol,
            onValidate: viewModel.validateAndCorrectAmount,
            focusedField: $focusedField,
            fieldValue: .amount
        )
    }

    private var descriptionCard: some View {
        LimitedTextField(
            icon: "text.alignleft",
            placeholder: itemListDescription,
            text: $viewModel.description,
            maxLength: 200,
            axis: .vertical,
            focusedField: $focusedField,
            fieldValue: .description
        )
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { max(1, Int(viewModel.quantity) ?? 1) },
            set: { viewModel.quantity = String($0) }
        )
    }

    private var quantityStepper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cantidad")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                Image(systemName: "number")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                TextField("1", text: $viewModel.quantity)
                    .keyboardType(.numberPad)
                    .font(.subheadline.weight(.semibold))
                    .focused($focusedField, equals: .quantity)
                    .onChange(of: viewModel.quantity) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        if let n = Int(digits) {
                            viewModel.quantity = String(min(n, 999999))
                        } else {
                            viewModel.quantity = digits
                        }
                    }

                Stepper("", value: quantityBinding, in: 1...999999)
                    .labelsHidden()
                    .fixedSize()
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
    }

    private var subtotalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Subtotal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(subtotalFormula)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(displayedSubtotal.isEmpty ? subtotalAmount : displayedSubtotal)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: subtotalIsDecreasing))
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: displayedSubtotal)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
        .onAppear { displayedSubtotal = subtotalAmount }
        .onChange(of: subtotalAmount) { _, newValue in
            let oldDigits = Int(displayedSubtotal.filter(\.isNumber)) ?? 0
            let newDigits = Int(newValue.filter(\.isNumber)) ?? 0
            subtotalIsDecreasing = newDigits < oldDigits
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                displayedSubtotal = newValue
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let itemList = SDItemList.mock(itemListDescription: "Compras del supermercado")
    let group = SDGroup.mock(name: "Casa", currency: "EUR")
    return NavigationStack {
        ItemListDetailView(itemList: itemList, currencyCode: "EUR", group: group)
    }
}
