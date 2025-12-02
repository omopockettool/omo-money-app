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

    // MARK: - Sheet Mode (UI State)
    enum ItemSheetMode: Identifiable {
        case create
        case edit(Item)

        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let item):
                return "edit-\(item.objectID)"
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
                    itemList: itemList,
                    context: context,
                    itemToEdit: nil,
                    onItemSaved: { newItem in
                        Task {
                            await viewModel.addItem(newItem)
                        }
                    },
                    createItemUseCase: createItemUseCase,
                    updateItemUseCase: updateItemUseCase
                )
            case .edit(let item):
                AddItemView(
                    itemList: itemList,
                    context: context,
                    itemToEdit: item,
                    onItemSaved: { savedItem in
                        Task {
                            await viewModel.updateItem(savedItem)
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
            ForEach(Array(viewModel.items.enumerated()), id: \.element.objectID) { index, item in
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
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let item = viewModel.items[index]
                        await viewModel.deleteItem(item, at: index)
                    }
                }
            }
        }
        .listStyle(.plain)
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
    let item: Item
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
                    Text(item.itemDescription ?? "Sin descripción")
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
    let itemList: ItemList
    let context: NSManagedObjectContext
    let itemToEdit: Item?
    let onItemSaved: (Item) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var amount = ""
    @State private var quantity = "1"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase
    private var isEditMode: Bool { itemToEdit != nil }

    init(
        itemList: ItemList,
        context: NSManagedObjectContext,
        itemToEdit: Item? = nil,
        onItemSaved: @escaping (Item) -> Void,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.itemList = itemList
        self.context = context
        self.itemToEdit = itemToEdit
        self.onItemSaved = onItemSaved
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase

        // Pre-populate fields if editing
        if let item = itemToEdit {
            _description = State(initialValue: item.itemDescription ?? "")
            _amount = State(initialValue: item.amount?.stringValue ?? "")
            _quantity = State(initialValue: String(item.quantity))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles del Item") {
                    TextField("Descripción", text: $description)
                    TextField("Cantidad", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Unidades", text: $quantity)
                        .keyboardType(.numberPad)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Editar Item" : "Nuevo Item")
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
                            await saveItem()
                        }
                    }
                    .disabled(isSaving || description.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    @MainActor
    private func saveItem() async {
        guard let amountDecimal = Decimal(string: amount),
              let quantityInt = Int32(quantity),
              let itemListId = itemList.id else {
            errorMessage = "Cantidad o unidades inválidas"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            if let existingItem = itemToEdit, let itemId = existingItem.id {
                // Edit mode - use Update Use Case
                let itemDomain = ItemDomain(
                    id: itemId,
                    itemDescription: description,
                    amount: amountDecimal,
                    quantity: quantityInt,
                    itemListId: itemListId,
                    createdAt: existingItem.createdAt ?? Date(),
                    lastModifiedAt: Date()
                )
                try await updateItemUseCase.execute(itemDomain)

                // Refresh the existing item from context
                context.refresh(existingItem, mergeChanges: true)
                onItemSaved(existingItem)
            } else {
                // Create mode - use Create Use Case
                let itemDomain = try await createItemUseCase.execute(
                    description: description,
                    amount: amountDecimal,
                    quantity: quantityInt,
                    itemListId: itemListId
                )

                // Fetch the created Core Data entity
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", itemDomain.id as CVarArg)
                guard let savedItem = try context.fetch(fetchRequest).first else {
                    throw RepositoryError.notFound
                }

                onItemSaved(savedItem)
            }

            dismiss()
        } catch {
            errorMessage = "Error al guardar item: \(error.localizedDescription)"
            isSaving = false
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
