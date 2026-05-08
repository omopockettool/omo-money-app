import SwiftUI

struct GroupPickerList: View {
    let groups: [SDGroup]
    let currentGroup: SDGroup
    let isChangingGroup: Bool
    let isDeletingGroup: Bool
    let canDeleteGroups: Bool
    let selectedGroupID: UUID?
    let onSelect: (SDGroup) -> Void
    let onEdit: (SDGroup) -> Void
    let onDelete: (SDGroup) -> Void

    var body: some View {
        List {
            ForEach(groups, id: \.id) { group in
                GroupPickerRow(
                    group: group,
                    currentGroup: currentGroup,
                    isChangingGroup: isChangingGroup,
                    isDeletingGroup: isDeletingGroup,
                    canDeleteGroups: canDeleteGroups,
                    selectedGroupID: selectedGroupID,
                    onSelect: { onSelect(group) },
                    onEdit: { onEdit(group) },
                    onDelete: { onDelete(group) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if canDeleteGroups {
                        Button {
                            onDelete(group)
                        } label: {
                            Label(LocalizationKey.General.delete.localized, systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    if !isDeletingGroup {
                        Button {
                            onEdit(group)
                        } label: {
                            Label(LocalizationKey.Group.details.localized, systemImage: "info")
                        }
                        .tint(.gray)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .disabled(isDeletingGroup)
    }
}

struct GroupPickerRow: View {
    let group: SDGroup
    let currentGroup: SDGroup
    let isChangingGroup: Bool
    let isDeletingGroup: Bool
    let canDeleteGroups: Bool
    let selectedGroupID: UUID?
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            GroupPickerSelectionIndicator(
                group: group,
                currentGroup: currentGroup,
                selectedGroupID: selectedGroupID,
                isChangingGroup: isChangingGroup
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formattedTotalSpent(for: group))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isChangingGroup && !isDeletingGroup else { return }
            onSelect()
        }
        .contextMenu {
            if !isDeletingGroup {
                Button(action: onEdit) {
                    Label(LocalizationKey.Group.details.localized, systemImage: "info.circle")
                }
            }
            if canDeleteGroups {
                Button(role: .destructive, action: onDelete) {
                    Label(LocalizationKey.General.delete.localized, systemImage: "trash")
                }
            }
        }
        .disabled(isChangingGroup || isDeletingGroup)
        .accessibilityLabel(LocalizationKey.Group.optionsFor.localized(with: group.name))
    }

    private func formattedTotalSpent(for group: SDGroup) -> String {
        let total = group.itemLists.reduce(0.0) { $0 + $1.totalAmount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = group.currency
        formatter.locale = Locale(identifier: "es_ES")

        let symbolFormatter = NumberFormatter()
        symbolFormatter.numberStyle = .currency
        symbolFormatter.currencyCode = group.currency
        symbolFormatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = symbolFormatter.currencySymbol

        return formatter.string(from: NSNumber(value: total)) ?? "\(total) \(group.currency)"
    }
}

struct GroupPickerSelectionIndicator: View {
    let group: SDGroup
    let currentGroup: SDGroup
    let selectedGroupID: UUID?
    let isChangingGroup: Bool

    var body: some View {
        if group.id == selectedGroupID && isChangingGroup {
            ProgressView()
                .scaleEffect(0.85)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: group.id == currentGroup.id ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(group.id == currentGroup.id ? .accentColor : Color(.systemGray3))
                .frame(width: 24, height: 24)
        }
    }
}

struct GroupDeleteOverlay: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text(LocalizationKey.Group.deleting.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 20)
                )
            }
    }
}
