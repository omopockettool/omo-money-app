//
//  GroupSelectorChipView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI
import CoreData

/// Chip selector de grupo con popover overlay
/// No mueve el layout, se sobrepone como CategoryPickerView/PaymentMethodPickerView
struct GroupSelectorChipView: View {
    let currentGroup: Group
    let availableGroups: [Group]
    let context: NSManagedObjectContext
    let userId: UUID
    let isChangingGroup: Bool  // ✅ Estado de carga del cambio de grupo
    let onGroupChange: (Group) -> Void
    let onGroupCreated: (Group) -> Void
    let onGroupDeleted: (Group) -> Void
    
    @State private var showingPicker = false
    
    var body: some View {
        // Chip pegado a la izquierda
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.caption2)
                
                Text(currentGroup.name ?? "Sin nombre")
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
                context: context,
                userId: userId,
                isChangingGroup: isChangingGroup,
                showingPicker: $showingPicker,  // ✅ Binding para cerrar el sheet
                onGroupChange: onGroupChange,
                onGroupCreated: onGroupCreated,
                onGroupDeleted: onGroupDeleted
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isChangingGroup)  // ✅ No permitir cerrar mientras carga
        }
    }
}

// MARK: - Group Picker Sheet
struct GroupPickerSheet: View {
    let currentGroup: Group
    @State private var availableGroups: [Group]
    let context: NSManagedObjectContext
    let userId: UUID
    let isChangingGroup: Bool  // ✅ Estado de carga
    @Binding var showingPicker: Bool  // ✅ Para cerrar el sheet
    let onGroupChange: (Group) -> Void
    let onGroupCreated: (Group) -> Void
    let onGroupDeleted: (Group) -> Void
    
    @State private var showingCreateGroup = false
    @State private var selectedGroupID: NSManagedObjectID?  // ✅ Track del grupo siendo cargado
    
    init(currentGroup: Group,
         availableGroups: [Group],
         context: NSManagedObjectContext,
         userId: UUID,
         isChangingGroup: Bool,
         showingPicker: Binding<Bool>,
         onGroupChange: @escaping (Group) -> Void,
         onGroupCreated: @escaping (Group) -> Void,
         onGroupDeleted: @escaping (Group) -> Void) {
        self.currentGroup = currentGroup
        self._availableGroups = State(initialValue: availableGroups)
        self.context = context
        self.userId = userId
        self.isChangingGroup = isChangingGroup
        self._showingPicker = showingPicker
        self.onGroupChange = onGroupChange
        self.onGroupCreated = onGroupCreated
        self.onGroupDeleted = onGroupDeleted
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableGroups, id: \.objectID) { group in
                    Button {
                        // Marcar el grupo como seleccionado y llamar al callback
                        selectedGroupID = group.objectID
                        onGroupChange(group)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.name ?? "Sin nombre")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(group.currency ?? "USD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Mostrar spinner si es el grupo seleccionado Y está cargando
                            if group.objectID == selectedGroupID && isChangingGroup {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                            // Mostrar checkmark si es el grupo actual Y NO está cargando
                            else if group.objectID == currentGroup.objectID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(isChangingGroup)  // ✅ Deshabilitar tap mientras carga
                    // Solo permitir eliminar si no es el último grupo
                    .deleteDisabled(availableGroups.count <= 1)
                }
                .onDelete { indexSet in
                    deleteGroup(at: indexSet)
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
                            .foregroundColor(isChangingGroup ? .gray : .accentColor)
                    }
                    .disabled(isChangingGroup)  // ✅ Deshabilitar mientras carga
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(
                    context: context,
                    userId: userId,
                    onGroupCreated: { newGroup in
                        // Actualizar lista local incrementalmente
                        availableGroups.append(newGroup)
                        // Notificar al ViewModel
                        onGroupCreated(newGroup)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: isChangingGroup) { oldValue, newValue in
                // ✅ Cuando termina de cargar (false), cerrar el sheet
                if oldValue == true && newValue == false && selectedGroupID != nil {
                    // Esperar un poquito para que el usuario vea el cambio
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingPicker = false
                        selectedGroupID = nil  // Reset
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Group
    private func deleteGroup(at offsets: IndexSet) {
        print("🗑️ [GroupPicker] deleteGroup() iniciado")
        print("🗑️ [GroupPicker] offsets: \(offsets)")
        print("🗑️ [GroupPicker] availableGroups.count ANTES: \(availableGroups.count)")
        print("🗑️ [GroupPicker] availableGroups ANTES: \(availableGroups.map { ($0.name ?? "Sin nombre", $0.objectID) })")
        
        guard let index = offsets.first else {
            print("❌ [GroupPicker] offsets.first es nil")
            return
        }
        
        print("🗑️ [GroupPicker] index extraído: \(index)")
        
        let groupToDelete = availableGroups[index]
        print("🗑️ [GroupPicker] Grupo a eliminar: '\(groupToDelete.name ?? "Sin nombre")' (ObjectID: \(groupToDelete.objectID))")
        print("🗑️ [GroupPicker] Grupo actual: '\(currentGroup.name ?? "Sin nombre")' (ObjectID: \(currentGroup.objectID))")
        
        // Prevenir eliminar el grupo actual
        if groupToDelete.objectID == currentGroup.objectID {
            print("⚠️ [GroupPicker] No se puede eliminar el grupo actual - CANCELADO")
            return
        }
        
        // Prevenir eliminar el último grupo
        if availableGroups.count <= 1 {
            print("⚠️ [GroupPicker] No se puede eliminar el último grupo - CANCELADO")
            return
        }
        
        print("✅ [GroupPicker] Validaciones pasadas, procediendo con eliminación...")
        
        Task {
            let groupService = GroupService(context: context)
            
            do {
                print("🔥 [GroupPicker] Llamando a groupService.deleteGroup()...")
                // Eliminar SOLO este grupo por su ObjectID
                try await groupService.deleteGroup(groupToDelete)
                print("✅ [GroupPicker] groupService.deleteGroup() completado")
                
                await MainActor.run {
                    print("🔄 [GroupPicker] MainActor - Actualizando listas locales...")
                    print("🔄 [GroupPicker] availableGroups.count ANTES de removeAll: \(availableGroups.count)")
                    
                    // Eliminar de la lista local por ObjectID (no por índice)
                    availableGroups.removeAll { $0.objectID == groupToDelete.objectID }
                    
                    print("🔄 [GroupPicker] availableGroups.count DESPUÉS de removeAll: \(availableGroups.count)")
                    print("🔄 [GroupPicker] availableGroups DESPUÉS: \(availableGroups.map { $0.name ?? "Sin nombre" })")
                    
                    print("📤 [GroupPicker] Llamando a onGroupDeleted callback...")
                    // Notificar al ViewModel
                    onGroupDeleted(groupToDelete)
                    print("✅ [GroupPicker] Eliminación completa")
                }
            } catch {
                print("❌ [GroupPicker] Error eliminando grupo '\(groupToDelete.name ?? "Unknown")': \(error)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    VStack {
        Spacer()
        
        HStack {
            GroupSelectorChipView(
                currentGroup: Group(),
                availableGroups: [Group(), Group()],
                context: context,
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
