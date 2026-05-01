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
    @State private var showMetaLabels: Bool = true
    @State private var lastAddedDescription: String = ""

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
                ProgressView(LocalizationKey.Item.loading.localized)
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
                    Button(LocalizationKey.Entry.edit.localized, systemImage: "pencil") {
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
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeInOut(duration: 0.5)) { showMetaLabels = false }
            }
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
                        lastAddedDescription = item.itemDescription
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

    // MARK: - Main Content

    private var mainContentView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, 4)
                .padding(.bottom, 2)

            itemsList
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, 4)
                .padding(.bottom, 2)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            heroCardInset
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ItemListDetailHeroCard(
            itemList: itemList,
            heroIsSuccess: heroIsSuccess,
            lastAddedDescription: lastAddedDescription,
            totalAmount: viewModel.getFormattedTotal(),
            unpaidTotal: viewModel.getFormattedUnpaidTotal(),
            showMetaLabels: showMetaLabels,
            onAddExpense: { sheetMode = .create }
        )
    }

    // MARK: - Items List (scrollable)

    private var itemsList: some View {
        ItemListItemsSection(
            items: viewModel.items,
            currencyCode: currencyCode,
            formattedAmount: viewModel.getFormattedAmount,
            onItemTap: { sheetMode = .edit($0) },
            onTogglePaid: { item in
                Task {
                    await viewModel.toggleItemPaid(item)
                    onPaidStatusChanged?()
                }
            },
            onDelete: { item, index in
                Task { await viewModel.deleteItem(item, at: index) }
            },
            onRefresh: { await viewModel.loadItems() }
        )
    }

    private var heroCardInset: some View {
        heroCard
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
    }

    private func errorView(_ message: String) -> some View {
        ItemListErrorState(message: message) {
            Task { await viewModel.loadItems() }
        }
    }
}

// MARK: - Item Row View

struct ItemRowView: View {
    let item: SDItem
    let formattedAmount: String
    let currencyCode: String
    let timelinePosition: TimelinePosition
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
        HStack(alignment: .center, spacing: 12) {
            Button(action: onTogglePaid) {
                TimelineRailView(
                    position: timelinePosition,
                    color: item.isPaid ? .green : Color(.systemGray3),
                    isActive: item.isPaid,
                    iconName: item.isPaid ? "checkmark.circle.fill" : "circle",
                    iconColor: item.isPaid ? .green : Color(.systemGray3)
                )
                .frame(width: 44)
            }
            .buttonStyle(PressHapticButtonStyle())

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemDescription)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if showsBreakdown {
                        Text("\(formattedUnitPrice) × \(item.quantity) \(LocalizationKey.Item.units.localized)")
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
            .padding(.top, 14)
            .padding(.bottom, 18)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.15))
                    .frame(height: 2.0)
                    .frame(maxWidth: 120)
            }
        }
        .padding(.trailing, 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
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
