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
    let onGroupChange: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    let onGroupCreated: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    let onGroupDeleted: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    
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
            // ✅ Clean Architecture: Get DeleteGroupUseCase from DI Container
            let deleteGroupUseCase = AppDIContainer.shared.makeGroupSceneDIContainer().makeDeleteGroupUseCase()

            GroupPickerSheet(
                currentGroup: currentGroup,
                availableGroups: availableGroups,
                userId: userId,
                isChangingGroup: isChangingGroup,
                showingPicker: $showingPicker,  // ✅ Binding para cerrar el sheet
                deleteGroupUseCase: deleteGroupUseCase,
                onGroupChange: onGroupChange,
                onGroupCreated: onGroupCreated,
                onGroupDeleted: onGroupDeleted
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isChangingGroup)  // ✅ No permitir cerrar mientras carga o elimina
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
    let onGroupChange: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    let onGroupCreated: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    let onGroupDeleted: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback

    // ✅ Clean Architecture: Use Cases instead of direct service access
    let deleteGroupUseCase: DeleteGroupUseCase

    @State private var showingCreateGroup = false
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
         deleteGroupUseCase: DeleteGroupUseCase,
         onGroupChange: @escaping (SDGroup) -> Void,
         onGroupCreated: @escaping (SDGroup) -> Void,
         onGroupDeleted: @escaping (SDGroup) -> Void) {
        self.currentGroup = currentGroup
        self._availableGroups = State(initialValue: availableGroups)
        self.userId = userId
        self.isChangingGroup = isChangingGroup
        self._showingPicker = showingPicker
        self.deleteGroupUseCase = deleteGroupUseCase
        self.onGroupChange = onGroupChange
        self.onGroupCreated = onGroupCreated
        self.onGroupDeleted = onGroupDeleted
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
                                    Label("Editar", systemImage: "pencil")
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
            .sheet(isPresented: $showingCreateGroup) {
                // ✅ Clean Architecture: Pass Use Cases from DI Container
                let appContainer = AppDIContainer.shared
                CreateGroupView(
                    createGroupUseCase: appContainer.makeCreateGroupUseCase(),
                    createUserGroupUseCase: appContainer.makeCreateUserGroupUseCase(),
                    userId: userId,
                    onGroupCreated: { newGroup in
                        availableGroups.append(newGroup)
                        onGroupCreated(newGroup)
                        onGroupChange(newGroup)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $groupToEdit) { group in
                NavigationStack {
                    GroupFormView(group: group) { }
                }
                .presentationDetents([.medium])
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
    private func deleteGroup(_ groupToDelete: SDGroup) {  // ✅ Clean Architecture: Domain parameter
        print("🗑️ [GroupPicker] deleteGroup() iniciado")
        print("🗑️ [GroupPicker] availableGroups.count ANTES: \(availableGroups.count)")
        print("🗑️ [GroupPicker] availableGroups ANTES: \(availableGroups.map { ($0.name, $0.id) })")  // ✅ Domain: .id UUID

        print("🗑️ [GroupPicker] Grupo a eliminar: '\(groupToDelete.name)' (ID: \(groupToDelete.id))")  // ✅ Domain: non-optional
        print("🗑️ [GroupPicker] Grupo actual: '\(currentGroup.name)' (ID: \(currentGroup.id))")  // ✅ Domain: non-optional

        // Prevenir eliminar el último grupo
        if availableGroups.count <= 1 {
            print("⚠️ [GroupPicker] No se puede eliminar el último grupo - CANCELADO")
            return
        }

        print("✅ [GroupPicker] Validaciones pasadas, procediendo con eliminación...")

        // Determinar si necesitamos cambiar de grupo después de eliminar
        let isDeletingCurrentGroup = groupToDelete.id == currentGroup.id  // ✅ Domain: UUID comparison
        var newGroupToSelect: SDGroup?  // ✅ Clean Architecture: Domain model

        if isDeletingCurrentGroup {
            // Buscar el primer grupo que no sea el que vamos a eliminar
            newGroupToSelect = availableGroups.first { $0.id != groupToDelete.id }  // ✅ Domain: UUID comparison
            print("⚠️ [GroupPicker] Eliminando grupo actual, cambiaremos a: '\(newGroupToSelect?.name ?? "Sin nombre")'")
        }

        // ✅ Activar estado de eliminación
        isDeletingGroup = true

        // 🔧 FIX: Eliminar de la lista local PRIMERO (optimistic update)
        // Esto previene el parpadeo visual del grupo desapareciendo y reapareciendo
        print("🔄 [GroupPicker] Eliminando de lista local ANTES de DB...")
        print("🔄 [GroupPicker] availableGroups.count ANTES de removeAll: \(availableGroups.count)")
        withAnimation { availableGroups.removeAll { $0.id == groupToDelete.id } }
        print("🔄 [GroupPicker] availableGroups.count DESPUÉS de removeAll: \(availableGroups.count)")
        print("🔄 [GroupPicker] availableGroups DESPUÉS: \(availableGroups.map { $0.name })")  // ✅ Domain: non-optional

        Task {
            do {
                print("🔥 [GroupPicker] Llamando a deleteGroupUseCase.execute()...")
                // ✅ Clean Architecture: Use Case handles everything (no Core Data conversion needed)
                try await deleteGroupUseCase.execute(groupId: groupToDelete.id)
                print("✅ [GroupPicker] deleteGroupUseCase.execute() completado")

                await MainActor.run {
                    print("📤 [GroupPicker] Llamando a onGroupDeleted callback...")
                    onGroupDeleted(groupToDelete)

                    if isDeletingCurrentGroup, let newGroup = newGroupToSelect {
                        print("🔄 [GroupPicker] Cambiando al nuevo grupo: '\(newGroup.name)'")
                        onGroupChange(newGroup)
                    }
                }

                try? await Task.sleep(for: .seconds(1.5))

                await MainActor.run {
                    isDeletingGroup = false
                    print("✅ [GroupPicker] Eliminación completa")
                }
            } catch {
                await MainActor.run {
                    // 🔧 En caso de error, RE-AGREGAR el grupo a la lista (rollback)
                    print("❌ [GroupPicker] Error en eliminación, restaurando grupo a la lista")
                    availableGroups.append(groupToDelete)
                    availableGroups.sort { $0.name < $1.name }  // ✅ Domain: non-optional

                    // ✅ Desactivar estado de eliminación
                    isDeletingGroup = false
                }
                print("❌ [GroupPicker] Error eliminando grupo '\(groupToDelete.name)': \(error)")  // ✅ Domain: non-optional
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
                onGroupDeleted: { _ in }
            )

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    .background(Color.black)
}
