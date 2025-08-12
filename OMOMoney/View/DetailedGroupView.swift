//
//  DetailedGroupView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct DetailedGroupView: View {
    @StateObject private var viewModel: DetailedGroupViewModel
    @Binding var navigationPath: NavigationPath
    
    @State private var showingSettings = false
    
    init(userViewModel: UserViewModel, 
         groupViewModel: GroupViewModel, 
         userGroupViewModel: UserGroupViewModel, 
         entryViewModel: EntryViewModel,
         navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: DetailedGroupViewModel(
            userViewModel: userViewModel,
            groupViewModel: groupViewModel,
            userGroupViewModel: userGroupViewModel,
            entryViewModel: entryViewModel
        ))
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Create Group and Settings buttons
                HStack {
                    Button(action: {
                        if let currentUser = viewModel.userViewModel.users.first {
                            navigationPath.append(CreateGroupDestination(user: currentUser))
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if let currentUser = viewModel.userViewModel.users.first {
                    // Group Selection Dropdown
                    VStack(spacing: 16) {
                        HStack {
                            Text("Grupo:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Menu {
                            ForEach(viewModel.userGroups(for: currentUser), id: \.id) { group in
                                Button(action: { viewModel.selectedGroup = group }) {
                                    HStack {
                                        Text(group.name ?? "Sin nombre")
                                        if viewModel.selectedGroup?.id == group.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedGroup?.name ?? "Seleccionar grupo")
                                    .foregroundColor(viewModel.selectedGroup == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    if let group = viewModel.selectedGroup {
                        // Total Spent Widget
                        VStack(spacing: 12) {
                            Text("Total Gastado")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if viewModel.isCalculatingTotal {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(viewModel.formatCurrency(viewModel.groupTotal))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .onAppear {
                            viewModel.calculateTotalForGroup(group)
                        }
                        
                        // Entries List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Gastos Recientes")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if viewModel.entryViewModel.isLoading {
                                ProgressView("Cargando gastos...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                let groupEntries = viewModel.entries(for: group)
                                if groupEntries.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        
                                        Text("No hay gastos registrados")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                        
                                        Text("Agrega tu primer gasto para comenzar")
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding()
                                } else {
                                    List {
                                        ForEach(groupEntries) { entry in
                                            EntryRowView(entry: entry)
                                        }
                                    }
                                    .listStyle(PlainListStyle())
                                }
                            }
                        }
                    } else {
                        // No group selected
                        VStack(spacing: 20) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Selecciona un grupo")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            Text("Elige un grupo para ver tus gastos")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                } else {
                    // No users
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No hay usuarios")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("Agrega un usuario para comenzar")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("OMOMoney")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings, navigationPath: $navigationPath)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    return DetailedGroupView(
        userViewModel: UserViewModel(context: context),
        groupViewModel: GroupViewModel(context: context),
        userGroupViewModel: UserGroupViewModel(context: context),
        entryViewModel: EntryViewModel(context: context),
        navigationPath: .constant(NavigationPath())
    )
}
