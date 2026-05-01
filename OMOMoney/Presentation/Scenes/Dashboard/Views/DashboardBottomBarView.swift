import SwiftUI

struct DashboardBottomBarView: View {
    let currentGroup: SDGroup?
    let availableGroups: [SDGroup]
    let userId: UUID?
    let isChangingGroup: Bool
    let isFilterActive: Bool
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async throws -> Void
    let onOpenFilters: () -> Void

    var body: some View {
        HStack(spacing: AppConstants.UserInterface.smallPadding) {
            if let currentGroup, let userId {
                GroupSelectorChipView(
                    currentGroup: currentGroup,
                    availableGroups: availableGroups,
                    userId: userId,
                    isChangingGroup: isChangingGroup,
                    onGroupChange: onGroupChange,
                    onGroupCreated: onGroupCreated,
                    onDeleteGroup: onDeleteGroup
                )
            }

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                Button(action: onOpenFilters) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isFilterActive ? .accentColor : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(PressHapticButtonStyle())

                Divider()
                    .frame(height: 16)

                Button { } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.smallPadding)
        .padding(.bottom, AppConstants.UserInterface.smallPadding)
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
    }
}
