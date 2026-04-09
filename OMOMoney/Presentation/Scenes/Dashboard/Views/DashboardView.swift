//
//  DashboardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

enum DashboardViewMode {
    case calendar, list

    var title: String {
        switch self {
        case .calendar: return "Calendario"
        case .list:     return "Lista"
        }
    }
}

/// Wrapper view to navigate to ItemListDetailView with proper currency
/// ✅ Clean Architecture: Works with Domain models only
struct ItemListDetailNavigationWrapper: View {
    let itemListDomain: ItemListDomain
    let currencyCode: String
    let group: GroupDomain
    let onItemListUpdated: (ItemListDomain) -> Void
    let onPaidStatusChanged: (() -> Void)?

    var body: some View {
        ItemListDetailView(
            itemListDomain: itemListDomain,
            currencyCode: currencyCode,
            group: group,
            onItemListUpdated: onItemListUpdated,
            onPaidStatusChanged: onPaidStatusChanged
        )
    }
}

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var contentOpacity: Double = 0.0
    @State private var hasLoadedInitialData = false
    @State private var showingAddItemList = false
    @State private var selectedCalendarDay: Date? = nil
    @State private var listDragOffset: CGFloat = 0
    @State private var viewMode: DashboardViewMode = .calendar

    init() {
        // ✅ Clean Architecture: Use DI Container for all dependencies
        let container = AppDIContainer.shared

        self._viewModel = StateObject(wrappedValue: DashboardViewModel(
            fetchItemListsUseCase: container.makeFetchItemListsUseCase(),
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            deleteItemListUseCase: container.makeDeleteItemListUseCase(),
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: container.makeFetchGroupsForUserUseCase(),
            fetchCategoriesUseCase: container.makeFetchCategoriesUseCase(),
            toggleAllItemsPaidInListUseCase: container.makeToggleAllItemsPaidInListUseCase()
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        mainContentView
                    }
                }
                .opacity(viewModel.isLoading ? 1.0 : contentOpacity)

                // Overlay sutil para cambio de grupo (NO splash completo)
                if viewModel.isChangingGroup {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)

                                Text("Cambiando grupo...")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isChangingGroup)
                }
            }
            .background(Color(.systemBackground))
            .onChange(of: viewModel.isChangingGroup) { _, changing in
                if !changing {
                    selectedCalendarDay = nil
                    listDragOffset = 0
                    viewMode = .calendar
                }
            }
            .navigationDestination(for: ItemListDomain.self) { itemListDomain in
                // ✅ Clean Architecture: Navigate with Domain model and currency
                if let group = viewModel.currentGroup {
                    ItemListDetailNavigationWrapper(
                        itemListDomain: itemListDomain,
                        currencyCode: group.currency,
                        group: group,
                        onItemListUpdated: { updated in
                            Task { await viewModel.updateItemListDomain(updated) }
                        },
                        onPaidStatusChanged: {
                            Task { await viewModel.refreshTotals() }
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                Task { await viewModel.refreshCategories() }
            } content: {
                if let group = viewModel.currentGroup, let user = viewModel.currentUser {
                    SettingsSheetView(
                        group: group,
                        user: user,
                        onUserUpdated: { updated in
                            viewModel.updateCurrentUser(updated)
                        }
                    )
                }
            }
            .sheet(isPresented: $showingAddItemList) {
                if let group = viewModel.currentGroup {
                    NavigationStack {
                        AddItemListView(
                            group: group,  // ✅ Already a Domain model
                            initialDate: selectedCalendarDay,
                            onItemListCreated: { createdItemList in
                                print("🔄 DashboardView: onItemListCreated callback triggered")
                                print("✅ DashboardView: Received new ItemList: '\(createdItemList.itemListDescription)'")
                                Task {
                                    print("⚡️ DashboardView: Using INCREMENTAL cache update")
                                    await viewModel.addItemListFromDomain(createdItemList)
                                    print("✅ DashboardView: Incremental update completed - UI updated instantly!")
                                }
                                showingAddItemList = false
                            },
                            onCancel: {
                                showingAddItemList = false
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            // Only load data on first appearance to avoid splash on navigation back
            guard !hasLoadedInitialData else {
                print("📍 DashboardView: Navigated back, refreshing data...")
                // 🔄 Refresh data to get updated totals
                Task {
                    await viewModel.refreshData()
                }
                return
            }

            hasLoadedInitialData = true
            Task {
                await viewModel.loadDashboardData()
                // Fade in suave del contenido después de cargar - SOLO UNA VEZ
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seg para asegurar render
                withAnimation(.easeIn(duration: 0.5)) {
                    contentOpacity = 1.0
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    private var loadingView: some View {
        Color(.systemBackground).ignoresSafeArea()
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
                    await viewModel.loadDashboardData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // iOS 26-style view picker dropdown
            viewPickerBar

            // Content switches based on selected view mode
            switch viewMode {
            case .calendar:
                CalendarGridView(
                    currentMonthItemLists: viewModel.currentMonthItemLists,
                    itemListTotals: viewModel.itemListTotals,
                    currencyCode: viewModel.currentGroup?.currency ?? "EUR",
                    selectedDay: selectedCalendarDay,
                    onDayTap: { date in
                        withAnimation(AnimationHelper.smoothSpring) {
                            if let current = selectedCalendarDay,
                               Calendar.current.isDate(current, inSameDayAs: date) {
                                selectedCalendarDay = nil
                            } else {
                                selectedCalendarDay = date
                                listDragOffset = 0
                            }
                        }
                    }
                )
                .frame(maxHeight: selectedCalendarDay == nil ? .infinity : nil)

                if selectedCalendarDay != nil {
                    dayListPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

            case .list:
                ExpenseListView(
                    itemLists: viewModel.currentMonthItemLists,
                    getFormattedAmount: { viewModel.formattedPaid(for: $0) },
                    getFormattedUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
                    itemListCounts: viewModel.itemListCounts,
                    categories: viewModel.categories,
                    itemListPaidStatus: viewModel.itemListPaidStatus,
                    onItemTap: { navigationPath.append($0) },
                    onTogglePaid: { viewModel.togglePaid(for: $0) },
                    onRefresh: { await viewModel.refreshData() },
                    onDelete: { await viewModel.deleteItemListDomain($0) }
                )
                .transition(.opacity)

            }

            // Bottom controls — always visible in all modes
            bottomControls
        }
        .ignoresSafeArea(.keyboard)
        .animation(AnimationHelper.smoothSpring, value: selectedCalendarDay == nil)
        .animation(AnimationHelper.quickEase, value: viewMode == .calendar)
    }

    // View picker: "Calendario ⌄" dropdown on left, search icon on right
    private var viewPickerBar: some View {
        HStack {
            Menu {
                Button {
                    withAnimation(AnimationHelper.quickEase) {
                        viewMode = .calendar
                        selectedCalendarDay = nil
                    }
                } label: {
                    Label("Calendario", systemImage: viewMode == .calendar ? "checkmark" : "calendar")
                }

                Button {
                    withAnimation(AnimationHelper.quickEase) {
                        viewMode = .list
                        selectedCalendarDay = nil
                    }
                } label: {
                    Label("Lista", systemImage: viewMode == .list ? "checkmark" : "list.bullet")
                }
            } label: {
                HStack(spacing: 5) {
                    Text(viewMode.title)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()

            Button { viewModel.openSettings() } label: {
                Image(systemName: "gear")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }


    private var dayListPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity)

            if let day = selectedCalendarDay {
                dayExpenseList(for: day)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
        .offset(y: listDragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    listDragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        withAnimation(AnimationHelper.smoothSpring) {
                            selectedCalendarDay = nil
                        }
                        listDragOffset = 0
                    } else {
                        withAnimation(AnimationHelper.smoothSpring) {
                            listDragOffset = 0
                        }
                    }
                }
        )
        .frame(maxHeight: .infinity)
    }

    private func dayExpenseList(for date: Date, onItemTap: ((ItemListDomain) -> Void)? = nil) -> some View {
        let cal = Calendar.current
        let filtered = viewModel.currentMonthItemLists.filter {
            cal.isDate($0.date, inSameDayAs: date)
        }
        return ExpenseListView(
            itemLists: filtered,
            getFormattedAmount: { viewModel.formattedPaid(for: $0) },
            getFormattedUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
            itemListCounts: viewModel.itemListCounts,
            categories: viewModel.categories,
            itemListPaidStatus: viewModel.itemListPaidStatus,
            onItemTap: { item in
                if let customTap = onItemTap { customTap(item) } else { navigationPath.append(item) }
            },
            onTogglePaid: { viewModel.togglePaid(for: $0) },
            onRefresh: { await viewModel.refreshData() },
            onDelete: { await viewModel.deleteItemListDomain($0) }
        )
        .frame(maxHeight: .infinity)
    }

    private func sheetTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Gastos de hoy" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM"
        let s = formatter.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private var displayedTotal: String {
        guard let day = selectedCalendarDay else { return viewModel.formattedTotalSpent }
        return viewModel.formattedTotal(for: day)
    }

    private var totalCardLabel: String {
        guard let day = selectedCalendarDay else { return "Coste de vida este mes" }
        if Calendar.current.isDateInToday(day) { return "Coste de vida hoy" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return "Coste del \(formatter.string(from: day))"
    }

    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: AppConstants.UserInterface.smallPadding) {
            TotalSpentCardView(
                label: totalCardLabel,
                totalAmount: displayedTotal,
                onAddExpense: { showingAddItemList = true }
            )

            // Group chips + Filters + Search in same row
            HStack(spacing: AppConstants.UserInterface.smallPadding) {
                if let currentGroup = viewModel.currentGroup,
                   let userId = viewModel.currentUser?.id {
                    GroupSelectorChipView(
                        currentGroup: currentGroup,
                        availableGroups: viewModel.availableGroups,
                        userId: userId,
                        isChangingGroup: viewModel.isChangingGroup,
                        onGroupChange: { newGroup in
                            Task { await viewModel.changeGroup(to: newGroup) }
                        },
                        onGroupCreated: { newGroup in
                            viewModel.addGroup(newGroup)
                        },
                        onGroupDeleted: { deletedGroup in
                            viewModel.removeGroup(deletedGroup)
                        }
                    )
                }

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    Button { } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .frame(height: 16)

                    Button { } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
        .background(Color(.systemBackground))
    }

    // MARK: - Debug Helper
    
    /// Debug function to log all entities in the database (moved from AppContentView)
    @MainActor
    private func logAllEntities() async {
        print("\n🔍 =========================")
        print("🔍 DEBUG: Logging all entities")
        print("🔍 =========================")
        
        if let currentUser = viewModel.currentUser {
                print("\n👤 USUARIO:")
                print("   ID: \(currentUser.id.uuidString)")  // ✅ id is NOT optional
                print("   Nombre: \(currentUser.name)")
                print("   Email: \(currentUser.email)")
                print("   Creado: \(currentUser.createdAt)")

                if let currentGroup = viewModel.currentGroup {
                    print("\n🏢 GRUPO ACTUAL:")
                    print("   ID: \(currentGroup.id.uuidString)")  // ✅ id is NOT optional
                    print("   Nombre: \(currentGroup.name)")
                    print("   Moneda: \(currentGroup.currency)")
                    print("   Creado: \(currentGroup.createdAt)")
                }
                
                print("\n📋 ITEM LISTS (\(viewModel.itemLists.count)):")
                for (index, itemList) in viewModel.itemLists.enumerated() {
                    print("   \(index + 1). ID: \(itemList.id.uuidString)")
                    print("      Descripción: \(itemList.itemListDescription)")
                    print("      Fecha: \(itemList.date)")
                    // TODO: getFormattedItemListTotal is async - need to calculate totals separately
                    print("      Total: (async calculation needed)")
                }
                
                print("\n💰 TOTAL GASTADO: \(viewModel.formattedTotalSpent)")
                
        } else {
            print("\n❌ No se encontró usuario actual")
        }
        
        print("🔍 =========================\n")
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}