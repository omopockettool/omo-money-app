//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import CoreData
import SwiftUI

struct CreateGroupView: View {
    @StateObject private var viewModel: CreateGroupViewModel
    @Binding var navigationPath: NavigationPath
    
    init(context: NSManagedObjectContext, user: User, navigationPath: Binding<NavigationPath>) {
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        let categoryService = CategoryService(context: context)
        
        self._viewModel = StateObject(wrappedValue: CreateGroupViewModel(
            user: user,
            groupService: groupService,
            userGroupService: userGroupService,
            categoryService: categoryService
        ))
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        Form {
            Section(header: Text("Group Information")) {
                TextField("Group Name", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.name) { _, _ in
                        // ✅ REACTIVO: Limpiar error cuando el usuario escribe
                        viewModel.clearError()
                    }
                
                Picker("Currency", selection: $viewModel.currency) {
                    ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // ✅ REACTIVO: Mostrar error si existe
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button("Create Group") {
                    Task {
                        await viewModel.createGroup()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
        .navigationTitle("Create Group")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    navigationPath.removeLast()
                }
            }
        }
        // ✅ REACTIVO: Navegar de vuelta cuando se complete la creación
        .onChange(of: viewModel.groupCreatedSuccessfully) { _, success in
            if success {
                navigationPath.removeLast()
            }
        }
        // ✅ REACTIVO: Mostrar loading state
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Creating group...")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create a mock user for preview
    let mockUser = User(context: context)
    mockUser.id = UUID()
    mockUser.name = "Usuario de Prueba"
    mockUser.email = "usuario@test.com"
    mockUser.createdAt = Date()
    mockUser.lastModifiedAt = Date()
    
    return CreateGroupView(
        context: context, 
        user: mockUser,
        navigationPath: .constant(NavigationPath())
    )
}
