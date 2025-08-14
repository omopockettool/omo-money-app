//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import CoreData

struct CreateGroupView: View {
    @StateObject private var viewModel: CreateGroupViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(context: NSManagedObjectContext, user: User) {
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        self._viewModel = StateObject(wrappedValue: CreateGroupViewModel(groupService: groupService, userGroupService: userGroupService, user: user))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Group Information")) {
                    TextField("Group Name", text: $viewModel.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Currency", selection: $viewModel.currency) {
                        ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("Create Group") {
                        Task {
                            await viewModel.createGroup()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.name.isEmpty)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.shouldNavigateBack) { oldValue, shouldNavigate in
                if shouldNavigate {
                    dismiss()
                    viewModel.resetForm()
                }
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
    
    return CreateGroupView(context: context, user: mockUser)
}
