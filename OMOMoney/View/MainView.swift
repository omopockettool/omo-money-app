//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import CoreData

struct MainView: View {
    @StateObject private var userViewModel: UserViewModel
    @State private var navigationPath = NavigationPath()
    
    init(context: NSManagedObjectContext) {
        _userViewModel = StateObject(wrappedValue: UserViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            UserListView(viewModel: userViewModel, navigationPath: $navigationPath)
                .navigationDestination(for: User.self) { user in
                    EditUserView(viewModel: userViewModel, user: user, navigationPath: $navigationPath)
                }
                .navigationDestination(for: AddUserDestination.self) { _ in
                    AddUserView(viewModel: userViewModel, navigationPath: $navigationPath)
                }
        }
    }
}

// MARK: - Navigation Destinations

struct AddUserDestination: Hashable {
    let id = UUID()
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
