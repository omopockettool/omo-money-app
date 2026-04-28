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

    @State private var showingCreateGroup = false
    @State private var groupToEdit: SDGroup?
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
                List {
                    ForEach(viewModel.availableGroups, id: \.id) { group in  // ✅ Domain: use .id
                        Button {
                            viewModel.selectGroup(group, onGroupChange: onGroupChange)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.name)  // ✅ Domain: non-optional name
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(group.currency)  // ✅ Domain: non-optional currency
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Mostrar spinner si es el grupo seleccionado Y está cargando
                                if group.id == viewModel.selectedGroupID && isChangingGroup {  // ✅ Domain: UUID
                                    ProgressView()
                                        .scaleEffect(0.9)
                                }
                                // Mostrar checkmark si es el grupo actual Y NO está cargando
                                else if group.id == currentGroup.id {  // ✅ Domain: UUID
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .disabled(isChangingGroup || viewModel.isDeletingGroup)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if viewModel.canDeleteGroups {
                                Button {
                                    viewModel.requestDelete(group)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            if !viewModel.isDeletingGroup {
                                Button {
                                    groupToEdit = group
                                } label: {
                                    Label("Detalles", systemImage: "info")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .disabled(viewModel.isDeletingGroup)  // ✅ Deshabilitar lista completa mientras se elimina
                
                // ✅ Overlay de eliminación con spinner
                if viewModel.isDeletingGroup {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Eliminando grupo...")
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
                
                // ✅ Custom Alert para eliminar
                if viewModel.showingDeleteAlert, let group = viewModel.groupToDelete {
                    CustomAlertView(
                        title: "¿Desea eliminar \(group.name)?",  // ✅ Domain: non-optional name
                        message: "Se eliminarán todos los datos asociados a este grupo.",
                        primaryButton: AlertButton(title: "Eliminar", style: .destructive) {
                            Task {
                                await viewModel.deleteSelectedGroup(
                                    currentGroup: currentGroup,
                                    onGroupChange: onGroupChange,
                                    onDeleteGroup: onDeleteGroup
                                )
                            }
                        },
                        secondaryButton: AlertButton(title: "Cancelar", style: .cancel) {
                            viewModel.cancelDelete()
                        },
                        isPresented: $viewModel.showingDeleteAlert
                    )
                }
            }
            .navigationTitle("Seleccionar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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
        }
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
