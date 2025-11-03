//
//  DashboardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showingAddItemList = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        let itemListService = ItemListService(context: context)
        let userService = UserService(context: context)
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(
            itemListService: itemListService,
            userService: userService,
            groupService: groupService,
            userGroupService: userGroupService
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    DashboardHeaderView(
                        groupName: viewModel.currentGroup?.name ?? "Mis gastos",
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
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        mainContentView(geometry: geometry)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationDestination(for: String.self) { destination in
                if destination == "addItemList",
                   let user = viewModel.currentUser,
                   let group = viewModel.currentGroup {
                    AddItemListView(
                        user: user,
                        group: group,
                        context: context,
                        navigationPath: $navigationPath,
                        onItemListCreated: {
                            print("🔄 DashboardView: onItemListCreated callback triggered")
                            Task {
                                print("🔄 DashboardView: Starting refresh...")
                                await viewModel.refreshData()
                                print("✅ DashboardView: Refresh completed")
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Private Views
    
    private var loadingView: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando gastos...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            // Expense list
            ExpenseListView(
                itemLists: viewModel.recentItemLists,
                getFormattedAmount: { itemList in
                    viewModel.getFormattedItemListTotal(itemList)
                },
                onItemTap: { itemList in
                    // TODO: Navigate to expense detail
                    print("Navigate to expense detail: \(itemList.objectID)")
                },
                onRefresh: {
                    await viewModel.refreshData()
                }
            )
            .frame(maxHeight: geometry.size.height - 120) // Reserve space for total card
            
            // Total spent card at bottom
            TotalSpentCardView(
                totalAmount: viewModel.formattedTotalSpent,
                onAddExpense: {
                    navigationPath.append("addItemList")
                }
            )
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
        
        do {
            if let currentUser = viewModel.currentUser {
                print("\n👤 USUARIO:")
                print("   ID: \(currentUser.id?.uuidString ?? "N/A")")
                print("   Nombre: \(currentUser.name ?? "N/A")")
                print("   Email: \(currentUser.email ?? "N/A")")
                print("   Creado: \(currentUser.createdAt ?? Date())")
                
                if let currentGroup = viewModel.currentGroup {
                    print("\n🏢 GRUPO ACTUAL:")
                    print("   ID: \(currentGroup.id?.uuidString ?? "N/A")")
                    print("   Nombre: \(currentGroup.name ?? "N/A")")
                    print("   Moneda: \(currentGroup.currency ?? "N/A")")
                    print("   Creado: \(currentGroup.createdAt ?? Date())")
                }
                
                print("\n📋 ITEM LISTS (\(viewModel.itemLists.count)):")
                for (index, itemList) in viewModel.itemLists.enumerated() {
                    print("   \(index + 1). ID: \(itemList.id?.uuidString ?? "N/A")")
                    print("      Descripción: \(itemList.itemListDescription ?? "N/A")")
                    print("      Fecha: \(itemList.date ?? Date())")
                    print("      Total: \(viewModel.getFormattedItemListTotal(itemList))")
                }
                
                print("\n💰 TOTAL GASTADO: \(viewModel.formattedTotalSpent)")
                
            } else {
                print("\n❌ No se encontró usuario actual")
            }
            
        } catch {
            print("\n❌ ERROR logging entities: \(error.localizedDescription)")
        }
        
        print("🔍 =========================\n")
    }
}

// MARK: - Preview
#Preview {
    DashboardView(context: PersistenceController.preview.container.viewContext)
}