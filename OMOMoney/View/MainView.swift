//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import CoreData
import SwiftUI

struct MainView: View {
    @StateObject private var detailedGroupViewModel: DetailedGroupViewModel
    @State private var navigationPath = NavigationPath()
    
    init(context: NSManagedObjectContext) {
        let userService = UserService(context: context)
        let groupService = GroupService(context: context)
        let userGroupService = UserGroupService(context: context)
        let entryService = EntryService(context: context)
        let itemService = ItemService(context: context)
        let categoryService = CategoryService(context: context)
        
        _detailedGroupViewModel = StateObject(wrappedValue: DetailedGroupViewModel(
            context: context,
            userService: userService,
            groupService: groupService,
            userGroupService: userGroupService,
            entryService: entryService,
            itemService: itemService,
            categoryService: categoryService
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            DetailedGroupView(
                context: detailedGroupViewModel.context,
                navigationPath: $navigationPath
            )
                .navigationDestination(for: User.self) { user in
                    EditUserView(user: user, context: detailedGroupViewModel.context, navigationPath: $navigationPath)
                }
                .navigationDestination(for: AddUserDestination.self) { _ in
                    AddUserView(context: detailedGroupViewModel.context, navigationPath: $navigationPath)
                }
                .navigationDestination(for: CreateGroupDestination.self) { destination in
                    switch destination {
                    case .createGroup(let user):
                        CreateGroupView(
                            context: detailedGroupViewModel.context, 
                            user: user,
                            navigationPath: $navigationPath
                        )
                    }
                }
                .navigationDestination(for: SettingsDestination.self) { destination in
                    switch destination {
                    case .settings:
                        SettingsView(navigationPath: $navigationPath)
                    }
                }
                .navigationDestination(for: AddEntryDestination.self) { destination in
                    switch destination {
                    case .addEntry(let user, let group):
                        AddEntryView(
                            user: user,
                            group: group,
                            context: detailedGroupViewModel.context,
                            navigationPath: $navigationPath
                        )
                    }
                }
        }
    }
}

// MARK: - Navigation Destinations
struct AddUserDestination: Hashable {
    let id = UUID()
}

enum CreateGroupDestination: Hashable {
    case createGroup(User)
}

enum SettingsDestination: Hashable {
    case settings
}

enum AddEntryDestination: Hashable {
    case addEntry(User, Group)
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
