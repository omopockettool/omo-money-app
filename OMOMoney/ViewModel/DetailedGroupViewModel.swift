import Foundation
import CoreData
import SwiftUI

@MainActor
class DetailedGroupViewModel: ObservableObject {
    @Published var selectedGroup: Group?
    @Published var groupTotal: NSDecimalNumber = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Group creation state
    @Published var isCreatingGroup = false
    @Published var groupCreationError: String?
    @Published var groupCreationSuccess = false
    @Published var shouldNavigateBack = false
    
    let userViewModel: UserViewModel
    let groupViewModel: GroupViewModel
    let userGroupViewModel: UserGroupViewModel
    let entryViewModel: EntryViewModel
    
    init(userViewModel: UserViewModel, 
         groupViewModel: GroupViewModel, 
         userGroupViewModel: UserGroupViewModel, 
         entryViewModel: EntryViewModel) {
        self.userViewModel = userViewModel
        self.groupViewModel = groupViewModel
        self.userGroupViewModel = userGroupViewModel
        self.entryViewModel = entryViewModel
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        userViewModel.fetchUsers()
        groupViewModel.fetchGroups()
        userGroupViewModel.fetchUserGroups()
        entryViewModel.fetchEntries()
        
        // Auto-select first group if available
        if let firstUser = userViewModel.users.first,
           selectedGroup == nil {
            let userGroups = userGroups(for: firstUser)
            selectedGroup = userGroups.first
        }
    }
    
    // MARK: - Helper Methods
    
    func userGroups(for user: User) -> [Group] {
        return userGroupViewModel.groups(for: user)
    }
    
    func entries(for group: Group) -> [Entry] {
        guard let groupId = group.id else {
            print("Error: Group ID is nil in entries(for:)")
            return []
        }
        
        return entryViewModel.entries.filter { entry in
            entry.group?.id == groupId
        }
    }
    
    func totalSpent(for group: Group) -> NSDecimalNumber {
        // This is a heavy calculation, should be done in background
        // For now, return a simple calculation, but in production this should be cached
        let groupEntries = entries(for: group)
        return groupEntries.reduce(NSDecimalNumber.zero) { total, entry in
            let entryItems = entry.items ?? NSSet()
            let entryAmount = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                guard let item = item as? Item else { return itemTotal }
                let itemAmount = item.amount ?? NSDecimalNumber.zero
                let itemQuantity = NSDecimalNumber(value: item.quantity)
                return itemTotal.safeAdd(itemAmount.multiplying(by: itemQuantity))
            }
            return total.safeAdd(entryAmount)
        }
    }
    
    func calculateTotalForGroup(_ group: Group) {
        isCalculatingTotal = true
        
        // Use Core Data context to perform calculation in background
        entryViewModel.context.perform {
            // Calculate total in background thread using Core Data
            let total = self.calculateTotalInBackground(for: group)
            
            // Update UI on main thread
            Task { @MainActor in
                self.groupTotal = total
                self.isCalculatingTotal = false
            }
        }
    }
    
    private func calculateTotalInBackground(for group: Group) -> NSDecimalNumber {
        // This method is called from Core Data context perform block
        guard let groupId = group.id else {
            print("Error: Group ID is nil")
            return NSDecimalNumber.zero
        }
        
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
        
        do {
            let groupEntries = try entryViewModel.context.fetch(request)
            
            return groupEntries.reduce(NSDecimalNumber.zero) { total, entry in
                let entryItems = entry.items ?? NSSet()
                let entryAmount = entryItems.reduce(NSDecimalNumber.zero) { itemTotal, item in
                    guard let item = item as? Item else { return itemTotal }
                    let itemAmount = item.amount ?? NSDecimalNumber.zero
                    let itemQuantity = NSDecimalNumber(value: item.quantity)
                    return itemTotal.safeAdd(itemAmount.multiplying(by: itemQuantity))
                }
                return total.safeAdd(entryAmount)
            }
        } catch {
            print("Error calculating total: \(error)")
            return NSDecimalNumber.zero
        }
    }
    
    func formatCurrency(_ amount: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedGroup?.currency ?? "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount) ?? "$0.00"
    }
    
    // MARK: - Group Creation
    
    func createGroup(name: String, currency: String, user: User) {
        // Prevent multiple calls
        guard !isCreatingGroup else { return }
        
        isCreatingGroup = true
        groupCreationError = nil
        groupCreationSuccess = false
        shouldNavigateBack = false
        
        // Create group in background using Core Data context
        groupViewModel.context.perform {
            // Create the group directly in Core Data
            let newGroup = Group(context: self.groupViewModel.context)
            newGroup.id = UUID()
            newGroup.name = name
            newGroup.currency = currency
            newGroup.createdAt = Date()
            newGroup.lastModifiedAt = Date()
            
            do {
                try self.groupViewModel.context.save()
                
                // Create user-group relationship
                let userGroup = UserGroup(context: self.userGroupViewModel.context)
                userGroup.id = UUID()
                userGroup.user = user
                userGroup.group = newGroup
                userGroup.role = "owner"
                userGroup.joinedAt = Date()
                
                try self.userGroupViewModel.context.save()
                
                // Update UI on main thread - Update only essential properties first
                Task { @MainActor in
                    self.groupCreationSuccess = true
                    self.selectedGroup = newGroup
                    self.isCreatingGroup = false
                    
                    // Set navigation flag after a small delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.shouldNavigateBack = true
                    }
                }
                
                // Refresh data in a separate task to avoid UI conflicts
                Task { @MainActor in
                    // Small delay to ensure UI updates are processed first
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    self.groupViewModel.fetchGroups()
                    self.userGroupViewModel.fetchUserGroups()
                }
            } catch {
                // Rollback on error
                self.groupViewModel.context.rollback()
                self.userGroupViewModel.context.rollback()
                
                Task { @MainActor in
                    self.groupCreationError = "Failed to create group: \(error.localizedDescription)"
                    self.isCreatingGroup = false
                }
            }
        }
    }
    
    func clearGroupCreationState() {
        // Clear all group creation state properties
        groupCreationError = nil
        groupCreationSuccess = false
        isCreatingGroup = false
        shouldNavigateBack = false
    }
}
