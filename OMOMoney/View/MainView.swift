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
    @StateObject private var groupViewModel: GroupViewModel
    @StateObject private var userGroupViewModel: UserGroupViewModel
    @State private var navigationPath = NavigationPath()
    
    init(context: NSManagedObjectContext) {
        _userViewModel = StateObject(wrappedValue: UserViewModel(context: context))
        _groupViewModel = StateObject(wrappedValue: GroupViewModel(context: context))
        _userGroupViewModel = StateObject(wrappedValue: UserGroupViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            DetailedGroupView(
                userViewModel: userViewModel,
                groupViewModel: groupViewModel,
                userGroupViewModel: userGroupViewModel,
                entryViewModel: EntryViewModel(context: userViewModel.context),
                navigationPath: $navigationPath
            )
            .navigationDestination(for: User.self) { user in
                EditUserView(
                    viewModel: userViewModel,
                    groupViewModel: groupViewModel,
                    userGroupViewModel: userGroupViewModel,
                    user: user,
                    navigationPath: $navigationPath
                )
            }
            .navigationDestination(for: AddUserDestination.self) { _ in
                AddUserView(viewModel: userViewModel, navigationPath: $navigationPath)
            }
            .navigationDestination(for: CreateGroupDestination.self) { destination in
                CreateGroupView(
                    detailedGroupViewModel: DetailedGroupViewModel(
                        userViewModel: userViewModel,
                        groupViewModel: groupViewModel,
                        userGroupViewModel: userGroupViewModel,
                        entryViewModel: EntryViewModel(context: userViewModel.context)
                    ),
                    user: destination.user,
                    navigationPath: $navigationPath
                )
            }
        }
    }
}

// MARK: - Navigation Destinations

struct AddUserDestination: Hashable {
    let id = UUID()
}

struct CreateGroupDestination: Hashable {
    let id = UUID()
    let user: User
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
