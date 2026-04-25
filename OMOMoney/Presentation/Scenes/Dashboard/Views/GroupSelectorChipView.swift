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
    let onDeleteGroup: (SDGroup) async -> Void

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
    @State private var availableGroups: [SDGroup]  // ✅ Clean Architecture: Domain models
    let userId: UUID
    let isChangingGroup: Bool  // ✅ Estado de carga
    @Binding var showingPicker: Bool  // ✅ Para cerrar el sheet
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async -> Void

    @State private var showingCreateGroup = false
    @State private var groupWasCreated = false
    @State private var selectedGroupID: UUID?
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: SDGroup?
    @State private var isDeletingGroup = false
    @State private var groupToEdit: SDGroup?

    init(currentGroup: SDGroup,
         availableGroups: [SDGroup],
         userId: UUID,
         isChangingGroup: Bool,
         showingPicker: Binding<Bool>,
         onGroupChange: @escaping (SDGroup) -> Void,
         onGroupCreated: @escaping (SDGroup) -> Void,
         onDeleteGroup: @escaping (SDGroup) async -> Void) {
        self.currentGroup = currentGroup
        self._availableGroups = State(initialValue: availableGroups)
        self.userId = userId
        self.isChangingGroup = isChangingGroup
        self._showingPicker = showingPicker
        self.onGroupChange = onGroupChange
        self.onGroupCreated = onGroupCreated
        self.onDeleteGroup = onDeleteGroup
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(availableGroups, id: \.id) { group in  // ✅ Domain: use .id
                        Button {
                            // Marcar el grupo como seleccionado y llamar al callback
                            selectedGroupID = group.id  // ✅ Domain: UUID
                            onGroupChange(group)
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
                                if group.id == selectedGroupID && isChangingGroup {  // ✅ Domain: UUID
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
                        .disabled(isChangingGroup || isDeletingGroup)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if availableGroups.count > 1 && !isDeletingGroup {
                                Button {
                                    groupToDelete = group
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            if !isDeletingGroup {
                                Button {
                                    groupToEdit = group
                                } label: {
                                    Label("Ajustes", systemImage: "gearshape.fill")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .disabled(isDeletingGroup)  // ✅ Deshabilitar lista completa mientras se elimina
                
                // ✅ Overlay de eliminación con spinner
                if isDeletingGroup {
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
                if showingDeleteAlert, let group = groupToDelete {
                    CustomAlertView(
                        title: "¿Desea eliminar \(group.name)?",  // ✅ Domain: non-optional name
                        message: "Se eliminarán todos los datos asociados a este grupo.",
                        primaryButton: AlertButton(title: "Eliminar", style: .destructive) {
                            isDeletingGroup = true
                            deleteGroup(group)
                            groupToDelete = nil
                        },
                        secondaryButton: AlertButton(title: "Cancelar", style: .cancel) {
                            groupToDelete = nil
                        },
                        isPresented: $showingDeleteAlert
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
                            .foregroundColor(isChangingGroup || isDeletingGroup ? .gray : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(isChangingGroup || isDeletingGroup)
                }
            }
            .sheet(isPresented: $showingCreateGroup, onDismiss: {
                if groupWasCreated {
                    groupWasCreated = false
                    showingPicker = false
                }
            }) {
                CreateGroupView(
                    userId: userId,
                    onGroupCreated: { newGroup in
                        availableGroups.append(newGroup)
                        onGroupCreated(newGroup)
                        onGroupChange(newGroup)
                        groupWasCreated = true
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
                if oldValue == true && newValue == false && selectedGroupID != nil {
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        showingPicker = false
                        selectedGroupID = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Group
    private func deleteGroup(_ groupToDelete: SDGroup) {
        guard availableGroups.count > 1 else { return }

        let isDeletingCurrentGroup = groupToDelete.id == currentGroup.id
        let newGroupToSelect = isDeletingCurrentGroup
            ? availableGroups.first { $0.id != groupToDelete.id }
            : nil

        isDeletingGroup = true
        withAnimation { availableGroups.removeAll { $0.id == groupToDelete.id } }

        Task {
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
