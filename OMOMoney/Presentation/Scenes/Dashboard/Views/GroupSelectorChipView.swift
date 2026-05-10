//
//  GroupSelectorChipView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI

/// ✅ Clean Architecture: Chip selector de grupo - no Core Data dependencies
/// No mueve el layout, se sobrepone como CategoryPickerView/PaymentMethodPickerView
struct GroupSelectorChipView: View {
    let currentGroup: SDGroup  // ✅ Clean Architecture: Domain model
    let availableGroups: [SDGroup]  // ✅ Clean Architecture: Domain models
    let userId: UUID
    let isChangingGroup: Bool  // ✅ Estado de carga del cambio de grupo
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async throws -> Void

    @State private var showingPicker = false
    
    var body: some View {
        // Chip pegado a la izquierda
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.caption2)

                Text(currentGroup.name)  // ✅ Domain model: non-optional name
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            GroupPickerSheet(
                currentGroup: currentGroup,
                availableGroups: availableGroups,
                userId: userId,
                isChangingGroup: isChangingGroup,
                showingPicker: $showingPicker,
                onGroupChange: onGroupChange,
                onGroupCreated: onGroupCreated,
                onDeleteGroup: onDeleteGroup
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isChangingGroup)
        }
    }
}

// MARK: - Group Picker Sheet
/// ✅ Clean Architecture: Works with Domain models only
struct GroupPickerSheet: View {
    let currentGroup: SDGroup  // ✅ Clean Architecture: Domain model
    let userId: UUID
    let isChangingGroup: Bool  // ✅ Estado de carga
    @Binding var showingPicker: Bool  // ✅ Para cerrar el sheet
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async throws -> Void

    @AppStorage("hasSeenGroupActionsHint") private var hasSeenGroupActionsHint = false
    @State private var showingCreateGroup = false
    @State private var groupToEdit: SDGroup?
    @State private var showingActionsHint = false
    @State private var viewModel: GroupPickerSheetViewModel

    init(currentGroup: SDGroup,
         availableGroups: [SDGroup],
         userId: UUID,
         isChangingGroup: Bool,
         showingPicker: Binding<Bool>,
         onGroupChange: @escaping (SDGroup) -> Void,
         onGroupCreated: @escaping (SDGroup) -> Void,
         onDeleteGroup: @escaping (SDGroup) async throws -> Void) {
        self.currentGroup = currentGroup
        self.userId = userId
        self.isChangingGroup = isChangingGroup
        self._showingPicker = showingPicker
        self.onGroupChange = onGroupChange
        self.onGroupCreated = onGroupCreated
        self.onDeleteGroup = onDeleteGroup
        self._viewModel = State(wrappedValue: GroupPickerSheetViewModel(availableGroups: availableGroups))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                GroupPickerList(
                    groups: viewModel.availableGroups,
                    currentGroup: currentGroup,
                    isChangingGroup: isChangingGroup,
                    isDeletingGroup: viewModel.isDeletingGroup,
                    canDeleteGroups: viewModel.canDeleteGroups,
                    selectedGroupID: viewModel.selectedGroupID,
                    onSelect: { group in
                        viewModel.selectGroup(group, onGroupChange: onGroupChange)
                    },
                    onEdit: { groupToEdit = $0 },
                    onDelete: { viewModel.requestDelete($0) }
                )
                
                if viewModel.isDeletingGroup {
                    GroupDeleteOverlay()
                }
                
                if viewModel.showingDeleteAlert, let group = viewModel.groupToDelete {
                    CustomAlertView(
                        title: LocalizationKey.Group.deleteConfirmTitle.localized(with: group.name),
                        message: LocalizationKey.Group.deleteWarning.localized,
                        primaryButton: AlertButton(title: LocalizationKey.General.delete.localized, style: .destructive) {
                            Task {
                                await viewModel.deleteSelectedGroup(
                                    currentGroup: currentGroup,
                                    onGroupChange: onGroupChange,
                                    onDeleteGroup: onDeleteGroup
                                )
                            }
                        },
                        secondaryButton: AlertButton(title: LocalizationKey.General.cancel.localized, style: .cancel) {
                            viewModel.cancelDelete()
                        },
                        isPresented: $viewModel.showingDeleteAlert
                    )
                }
            }
            .navigationTitle(LocalizationKey.Group.selectGroup.localized)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                if showingActionsHint {
                    GroupActionsHintBanner {
                        withAnimation(AnimationHelper.quickEase) {
                            showingActionsHint = false
                        }
                    }
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                    .padding(.top, AppConstants.UserInterface.smallPadding)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(isChangingGroup || viewModel.isDeletingGroup ? .gray : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(isChangingGroup || viewModel.isDeletingGroup)
                }
            }
            .sheet(isPresented: $showingCreateGroup, onDismiss: {
                if viewModel.groupWasCreated {
                    viewModel.groupWasCreated = false
                    showingPicker = false
                }
            }) {
                CreateGroupView(
                    userId: userId,
                    onGroupCreated: { newGroup in
                        viewModel.handleGroupCreated(
                            newGroup,
                            onGroupCreated: onGroupCreated,
                            onGroupChange: onGroupChange
                        )
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemGroupedBackground))
            }
            .sheet(item: $groupToEdit) { group in
                NavigationStack {
                    GroupFormView(group: group) { }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: isChangingGroup) { oldValue, newValue in
                Task {
                    if await viewModel.finishGroupChangeIfNeeded(wasChanging: oldValue, isChanging: newValue) {
                        showingPicker = false
                    }
                }
            }
            .task {
                guard !hasSeenGroupActionsHint else { return }
                hasSeenGroupActionsHint = true
                withAnimation(AnimationHelper.quickEase) {
                    showingActionsHint = true
                }
                try? await Task.sleep(for: .seconds(4.6))
                guard showingActionsHint else { return }
                withAnimation(AnimationHelper.quickEase) {
                    showingActionsHint = false
                }
            }
        }
        .presentationBackground(Color(.systemGroupedBackground))
    }
}

private struct GroupActionsHintBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.accent)

            Text(LocalizationKey.Group.holdForActions.localized)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()

        HStack {
            GroupSelectorChipView(
                currentGroup: SDGroup.mock(name: "Personal", currency: "EUR"),  // ✅ Domain mock
                availableGroups: [  // ✅ Domain mocks
                    SDGroup.mock(name: "Personal", currency: "EUR"),
                    SDGroup.mock(name: "Work", currency: "USD")
                ],
                userId: UUID(),
                isChangingGroup: false,
                onGroupChange: { _ in },
                onGroupCreated: { _ in },
                onDeleteGroup: { _ in }
            )

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    .background(Color.black)
}
