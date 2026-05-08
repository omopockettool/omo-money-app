import Foundation

@MainActor
@Observable
final class GroupPickerSheetViewModel {
    var availableGroups: [SDGroup]
    var groupWasCreated = false
    var selectedGroupID: UUID?
    var showingDeleteAlert = false
    var groupToDelete: SDGroup?
    var isDeletingGroup = false

    init(availableGroups: [SDGroup]) {
        self.availableGroups = availableGroups
    }

    var canDeleteGroups: Bool {
        availableGroups.count > 1 && !isDeletingGroup
    }

    func selectGroup(_ group: SDGroup, onGroupChange: (SDGroup) -> Void) {
        selectedGroupID = group.id
        onGroupChange(group)
    }

    func requestDelete(_ group: SDGroup) {
        groupToDelete = group
        showingDeleteAlert = true
    }

    func cancelDelete() {
        groupToDelete = nil
    }

    func handleGroupCreated(
        _ newGroup: SDGroup,
        onGroupCreated: (SDGroup) -> Void,
        onGroupChange: (SDGroup) -> Void
    ) {
        availableGroups.append(newGroup)
        onGroupCreated(newGroup)
        onGroupChange(newGroup)
        groupWasCreated = true
    }

    func finishGroupChangeIfNeeded(wasChanging: Bool, isChanging: Bool) async -> Bool {
        guard wasChanging, !isChanging, selectedGroupID != nil else { return false }
        try? await Task.sleep(for: .milliseconds(300))
        selectedGroupID = nil
        return true
    }

    func deleteSelectedGroup(
        currentGroup: SDGroup,
        onGroupChange: (SDGroup) -> Void,
        onDeleteGroup: (SDGroup) async throws -> Void
    ) async {
        guard let groupToDelete else { return }
        await deleteGroup(
            groupToDelete,
            currentGroup: currentGroup,
            onGroupChange: onGroupChange,
            onDeleteGroup: onDeleteGroup
        )
    }

    private func deleteGroup(
        _ groupToDelete: SDGroup,
        currentGroup: SDGroup,
        onGroupChange: (SDGroup) -> Void,
        onDeleteGroup: (SDGroup) async throws -> Void
    ) async {
        guard availableGroups.count > 1 else { return }

        let isDeletingCurrentGroup = groupToDelete.id == currentGroup.id
        let newGroupToSelect = isDeletingCurrentGroup
            ? availableGroups.first { $0.id != groupToDelete.id }
            : nil

        isDeletingGroup = true
        self.groupToDelete = nil
        availableGroups.removeAll { $0.id == groupToDelete.id }

        do {
            try await onDeleteGroup(groupToDelete)

            if isDeletingCurrentGroup, let newGroup = newGroupToSelect {
                onGroupChange(newGroup)
            }

            try? await Task.sleep(for: .seconds(1.5))
            isDeletingGroup = false
        } catch {
            availableGroups.append(groupToDelete)
            availableGroups.sort { $0.name < $1.name }
            isDeletingGroup = false
        }
    }
}
