//
//  DashboardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

/// Wrapper view to navigate to ItemListDetailView with proper currency
/// ✅ Clean Architecture: Works with Domain models only
struct ItemListDetailNavigationWrapper: View {
    let itemListDomain: ItemListDomain
    let currencyCode: String

    var body: some View {
        ItemListDetailView(itemListDomain: itemListDomain, currencyCode: currencyCode)
    }
}

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var contentOpacity: Double = 0.0
    @State private var hasLoadedInitialData = false  // Track if we've loaded data already
    @State private var showingAddItemList = false

    init() {
        // ✅ Clean Architecture: Use DI Container for all dependencies
        let container = AppDIContainer.shared

        self._viewModel = StateObject(wrappedValue: DashboardViewModel(
            fetchItemListsUseCase: container.makeFetchItemListsUseCase(),
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            deleteItemListUseCase: container.makeDeleteItemListUseCase(),
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: container.makeFetchGroupsForUserUseCase(),
            fetchCategoriesUseCase: container.makeFetchCategoriesUseCase()
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        // Solo mostrar splash, sin header
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        // Header + Error view
                        DashboardHeaderView(
                            onSettingsTap: {
                                viewModel.openSettings()
                            },
                            onDebugTap: {
                                Task {
                                    await logAllEntities()
                                }
                            }
                        )
                        .background(Color(.systemBackground))
                        
                        errorView(errorMessage)
                    } else {
                        // Header + Main content
                        DashboardHeaderView(
                            onSettingsTap: {
                                viewModel.openSettings()
                            },
                            onDebugTap: {
                                Task {
                                    await logAllEntities()
                                }
                            }
                        )
                        .background(Color(.systemBackground))
                        
                        mainContentView(geometry: geometry)
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
            .navigationDestination(for: ItemListDomain.self) { itemListDomain in
                // ✅ Clean Architecture: Navigate with Domain model and currency
                ItemListDetailNavigationWrapper(
                    itemListDomain: itemListDomain,
                    currencyCode: viewModel.currentGroup?.currency ?? "EUR"
                )
            }
            .sheet(isPresented: $showingAddItemList) {
                if let user = viewModel.currentUser,
                   let group = viewModel.currentGroup {
                    NavigationStack {
                        AddItemListView(
                            user: user,  // ✅ Already a Domain model
                            group: group,  // ✅ Already a Domain model
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
        SplashView()
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
    
    private func mainContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Expense list - ONLY this component has refresh behavior
            ExpenseListView(
                itemLists: viewModel.currentMonthItemLists,
                getFormattedAmount: { itemList in
                    // ✅ Use cached total from itemListTotals dictionary
                    if let total = viewModel.itemListTotals[itemList.id] {
                        let code = viewModel.currentGroup?.currency ?? "EUR"
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        formatter.currencyCode = code
                        formatter.locale = Locale(identifier: "es_ES")
                        let sym = NumberFormatter()
                        sym.numberStyle = .currency
                        sym.currencyCode = code
                        sym.locale = Locale(identifier: "en_US")
                        formatter.currencySymbol = sym.currencySymbol
                        return formatter.string(from: NSNumber(value: total)) ?? "€0.00"
                    } else {
                        // This should not happen after the currentMonthCache fix
                        print("⚠️ [UI] ItemList '\(itemList.itemListDescription)' not found in itemListTotals")
                        return "€0.00"
                    }
                },
                itemListCounts: viewModel.itemListCounts,
                onItemTap: { itemList in
                    navigationPath.append(itemList)
                },
                onRefresh: {
                    await viewModel.refreshData()
                },
                onDelete: { itemListDomain in
                    // ✅ Clean Architecture: Use Domain method directly
                    await viewModel.deleteItemListDomain(itemListDomain)
                }
            )
            
            // Bottom controls - NEAR UX
            VStack(alignment: .leading, spacing: AppConstants.UserInterface.padding) {
                // Total spent card
                TotalSpentCardView(
                    totalAmount: viewModel.formattedTotalSpent,
                    onAddExpense: {
                        showingAddItemList = true
                    }
                )
                
                // Chip selector pegado a la izquierda (debajo del Total)
                // ✅ Clean Architecture: No Core Data context needed
                if let currentGroup = viewModel.currentGroup,
                   let userId = viewModel.currentUser?.id {
                    GroupSelectorChipView(
                        currentGroup: currentGroup,  // ✅ GroupDomain
                        availableGroups: viewModel.availableGroups,  // ✅ [GroupDomain]
                        userId: userId,
                        isChangingGroup: viewModel.isChangingGroup,  // ✅ Pasar estado de carga
                        onGroupChange: { newGroup in  // ✅ newGroup is GroupDomain
                            Task {
                                await viewModel.changeGroup(to: newGroup)
                            }
                        },
                        onGroupCreated: { newGroup in  // ✅ newGroup is GroupDomain
                            // Incremental update sin query
                            viewModel.addGroup(newGroup)
                        },
                        onGroupDeleted: { deletedGroup in  // ✅ deletedGroup is GroupDomain
                            // Incremental delete
                            viewModel.removeGroup(deletedGroup)
                        }
                    )
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.systemBackground))
        }
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