//
//  ItemListDetailView.swift
//  OMOMoney
//
//  Created by System on 29/11/25.
//

import SwiftUI
import CoreData

struct ItemListDetailView: View {
    let itemList: ItemList
    let context: NSManagedObjectContext

    @StateObject private var viewModel: ItemListDetailViewModel
    @State private var sheetMode: ItemSheetMode?  // UI state only
    @State private var hasLoadedInitialData = false  // Track if we've loaded data already

    // MARK: - Sheet Mode (UI State)
    enum ItemSheetMode: Identifiable {
        case create
        case edit(ItemDomain)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let item):
                return "edit-\(item.id)"
            }
        }
    }

    init(itemList: ItemList, context: NSManagedObjectContext) {
        self.itemList = itemList
        self.context = context

        // ✅ Create use cases here (View layer responsibility)
        let itemService = ItemService(context: context)
        let itemRepository = DefaultItemRepository(itemService: itemService, context: context)

        let fetchItemsUseCase = DefaultFetchItemsUseCase(itemRepository: itemRepository)
        let createItemUseCase = DefaultCreateItemUseCase(itemRepository: itemRepository)
        let updateItemUseCase = DefaultUpdateItemUseCase(itemRepository: itemRepository)
        let deleteItemUseCase = DefaultDeleteItemUseCase(itemRepository: itemRepository)

        // ✅ Inject use cases into ViewModel (Dependency Injection)
        self._viewModel = StateObject(wrappedValue: ItemListDetailViewModel(
            itemList: itemList,
            context: context,
            fetchItemsUseCase: fetchItemsUseCase,
            createItemUseCase: createItemUseCase,
            updateItemUseCase: updateItemUseCase,
            deleteItemUseCase: deleteItemUseCase
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
        .navigationTitle(itemList.itemListDescription ?? "Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Only load data on first appearance to avoid DB query on sheet dismiss
            guard !hasLoadedInitialData else {
                print("📍 ItemListDetailView: Sheet dismissed, reloading items...")
                // ✅ Reload items to get updated values
                Task {
                    await viewModel.loadItems()
                }
                return
            }

            hasLoadedInitialData = true
            Task {
                await viewModel.loadItems()
            }
        }
        .sheet(item: $sheetMode) { mode in
            // Create use cases for AddItemView
            let itemService = ItemService(context: context)
            let itemRepository = DefaultItemRepository(itemService: itemService, context: context)
            let createItemUseCase = DefaultCreateItemUseCase(itemRepository: itemRepository)
            let updateItemUseCase = DefaultUpdateItemUseCase(itemRepository: itemRepository)

            switch mode {
            case .create:
                AddItemView(
                    itemListId: itemList.id!,
                    itemToEdit: nil,
                    onItemSaved: { itemDomain in
                        Task {
                            // Convert ItemDomain to Core Data entity
                            await viewModel.addItemFromDomain(itemDomain)
                        }
                    },
                    createItemUseCase: createItemUseCase,
                    updateItemUseCase: updateItemUseCase
                )
            case .edit(let item):
                AddItemView(
                    itemListId: itemList.id!,
                    itemToEdit: item,
                    onItemSaved: { itemDomain in
                        Task {
                            // Convert ItemDomain to Core Data entity
                            await viewModel.updateItemFromDomain(itemDomain)
                        }
                    },
                    createItemUseCase: createItemUseCase,
                    updateItemUseCase: updateItemUseCase
                )
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

            // Total card at bottom
            VStack(spacing: AppConstants.UserInterface.padding) {
                TotalSpentCardView(
                    totalAmount: viewModel.getFormattedTotal(),
                    onAddExpense: {
                        sheetMode = .create
                    }
                )
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.systemBackground))
        }
    }

    private var itemsListView: some View {
        List {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                ItemRowView(
                    item: item,
                    formattedAmount: viewModel.getFormattedAmount(item),
                    onTap: {
                        sheetMode = .edit(item)
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
                        Task {
                            await viewModel.deleteItem(item, at: index)
                        }
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
                Task {
                    await viewModel.loadItems()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Item Row View Component

struct ItemRowView: View {
    let item: ItemDomain
    let formattedAmount: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.UserInterface.padding) {
                // Checkmark circle
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                // Content area
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemDescription)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Quantity badge
                    Text("Cantidad: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(AppConstants.UserInterface.cornerRadius / 2)
                }

                Spacer()

                // Amount
                Text(formattedAmount)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.systemGray5))
            .cornerRadius(AppConstants.UserInterface.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add/Edit Item View

struct AddItemView: View {
    let onItemSaved: (ItemDomain) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddItemViewModel

    init(
        itemListId: UUID,
        itemToEdit: ItemDomain? = nil,
        onItemSaved: @escaping (ItemDomain) -> Void,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.onItemSaved = onItemSaved
        self._viewModel = StateObject(wrappedValue: AddItemViewModel(
            itemListId: itemListId,
            itemToEdit: itemToEdit,
            createItemUseCase: createItemUseCase,
            updateItemUseCase: updateItemUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles del Item") {
                    TextField("Descripción", text: $viewModel.description)
                    TextField("Cantidad", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.amount) { oldValue, newValue in
                            viewModel.validateAndCorrectAmount()
                        }
                    TextField("Unidades", text: $viewModel.quantity)
                        .keyboardType(.numberPad)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Editar Item" : "Nuevo Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            if let itemDomain = await viewModel.saveItem() {
                                print("✅ AddItemView: Item saved, calling callback with ItemDomain")
                                onItemSaved(itemDomain)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let itemList = ItemList(context: context)
    itemList.itemListDescription = "Compras del supermercado"
    itemList.date = Date()

    let group = Group(context: context)
    group.currency = "EUR"
    itemList.group = group

    return NavigationStack {
        ItemListDetailView(itemList: itemList, context: context)
    }
}
