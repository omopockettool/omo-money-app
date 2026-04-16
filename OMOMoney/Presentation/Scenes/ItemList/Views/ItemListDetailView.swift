//
//  ItemListDetailView.swift
//  OMOMoney
//

import SwiftUI

struct ItemListDetailView: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let onItemListUpdated: ((SDItemList) -> Void)?

    @State private var viewModel: ItemListDetailViewModel
    @State private var sheetMode: ItemSheetMode?
    @State private var hasLoadedInitialData = false

    // MARK: - Sheet Mode (UI State)
    enum ItemSheetMode: Identifiable {
        case create
        case edit(SDItem)
        case editRegistry

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let item):
                return "edit-\(item.id)"
            case .editRegistry:
                return "editRegistry"
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
                ProgressView("Cargando items...")
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
                print("📍 ItemListDetailView: Sheet dismissed, reloading items...")
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
                    onItemSaved: { item in
                        Task { await viewModel.updateItem(item) }
                    },
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

    // MARK: - UI Components

    private var mainContentView: some View {
        VStack(spacing: 0) {
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                itemsListView
            }

            VStack(spacing: AppConstants.UserInterface.padding) {
                TotalSpentCardView(
                    label: "Coste de \(itemList.itemListDescription)",
                    totalAmount: viewModel.getFormattedTotal(),
                    onAddExpense: {
                        sheetMode = .create
                    }
                )
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(.keyboard)
    }

    private var itemsListView: some View {
        List {
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
                .listRowInsets(EdgeInsets(
                    top: 4,
                    leading: AppConstants.UserInterface.padding,
                    bottom: 4,
                    trailing: AppConstants.UserInterface.padding
                ))
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.2), value: viewModel.items.count)
        .refreshable {
            await viewModel.loadItems()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No hay items")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Agrega tu primer item con el botón +")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppConstants.UserInterface.largePadding)
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

// MARK: - Item Row View Component

struct ItemRowView: View {
    let item: SDItem
    let formattedAmount: String
    let currencyCode: String
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    private var showsBreakdown: Bool { item.quantity > 1 }
    private var isPending: Bool { !item.isPaid }

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
                        .foregroundStyle(isPending ? .secondary : .primary)
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
                    .foregroundStyle(isPending ? .secondary : .primary)
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

    // MARK: - Computed

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var quantityValue: Int {
        Int(viewModel.quantity) ?? 1
    }

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

    // MARK: - Body

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
            .navigationTitle(viewModel.isEditMode ? "Editar Item" : "Nuevo Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            if let item = await viewModel.saveItem() {
                                onItemSaved(item)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focusedField = nil }
                }
            }
        }
    }

    // MARK: - Hero Amount Input

    private var heroAmountInput: some View {
        HeroAmountInputView(
            text: $viewModel.amount,
            currencySymbol: currencySymbol,
            onValidate: viewModel.validateAndCorrectAmount,
            focusedField: $focusedField,
            fieldValue: .amount
        )
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        LimitedTextField(
            icon: "text.alignleft",
            placeholder: itemListDescription,
            text: $viewModel.description,
            focusedField: $focusedField,
            fieldValue: .description
        )
    }

    // MARK: - Quantity Stepper

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

    // MARK: - Subtotal Card

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
        .onAppear {
            displayedSubtotal = subtotalAmount
        }
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
        ItemListDetailView(
            itemList: itemList,
            currencyCode: "EUR",
            group: group
        )
    }
}
