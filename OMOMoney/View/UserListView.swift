//
//  UserListView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import CoreData

struct UserListView: View {
    @ObservedObject var viewModel: UserViewModel
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading users...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if viewModel.users.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.3")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Users Yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    Text("Tap the + button to add your first user")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.users) { user in
                        UserRowView(user: user) {
                            navigationPath.append(user)
                        }
                    }
                    .onDelete(perform: deleteUsers)
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { navigationPath.append(AddUserDestination()) }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteUsers(offsets: IndexSet) {
        for index in offsets {
            let user = viewModel.users[index]
            _ = viewModel.deleteUser(user)
        }
    }
}

#Preview {
    UserListView(
        viewModel: UserViewModel(context: PersistenceController.preview.container.viewContext),
        navigationPath: .constant(NavigationPath())
    )
}
