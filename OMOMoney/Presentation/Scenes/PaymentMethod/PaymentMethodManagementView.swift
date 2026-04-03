import SwiftUI

struct PaymentMethodManagementView: View {
    let group: GroupDomain

    @StateObject private var viewModel = PaymentMethodListViewModel()
    @State private var sheetMode: SheetMode?

    enum SheetMode: Identifiable {
        case add
        case edit(PaymentMethodDomain)
        var id: String {
            switch self { case .add: return "add"; case .edit(let pm): return pm.id.uuidString }
        }
    }

    var body: some View {
        List {
            ForEach(viewModel.paymentMethods) { pm in
                paymentMethodRow(pm)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !pm.isDefault {
                            Button(role: .destructive) {
                                Task { await viewModel.deletePaymentMethod(paymentMethodId: pm.id) }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Métodos de pago")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { sheetMode = .add } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $sheetMode) { mode in
            NavigationStack {
                switch mode {
                case .add:
                    PaymentMethodFormView(group: group, methodToEdit: nil) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                case .edit(let pm):
                    PaymentMethodFormView(group: group, methodToEdit: pm) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                }
            }
        }
        .task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
    }

    private func paymentMethodRow(_ pm: PaymentMethodDomain) -> some View {
        Button { if !pm.isDefault { sheetMode = .edit(pm) } } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(typeColor(pm.type).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: typeIcon(pm.type))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(typeColor(pm.type))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pm.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(typeName(pm.type))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if pm.isDefault {
                    Text("Predeterminado")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return "banknote.fill" }
        if t.contains("transfer") { return "arrow.left.arrow.right" }
        if t.contains("digital") || t.contains("wallet") || t.contains("paypal") { return "iphone" }
        return "creditcard.fill"
    }

    private func typeColor(_ type: String) -> Color {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return .green }
        if t.contains("transfer") { return .orange }
        if t.contains("digital") || t.contains("wallet") { return .purple }
        return .blue
    }

    private func typeName(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return "Efectivo" }
        if t.contains("transfer") { return "Transferencia" }
        if t.contains("digital") || t.contains("wallet") { return "Digital" }
        if t.contains("debit") { return "Débito" }
        return type.isEmpty ? "Tarjeta" : type
    }
}

// MARK: - Payment Method Form

struct PaymentMethodFormView: View {
    let group: GroupDomain
    let methodToEdit: PaymentMethodDomain?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaymentMethodListViewModel()

    @State private var name = ""
    @State private var selectedType = "card"
    @FocusState private var nameFocused: Bool?

    private let types = ["card", "cash", "transfer", "digital"]
    private var isEditMode: Bool { methodToEdit != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Preview
                ZStack {
                    Circle()
                        .fill(typeColor(selectedType).opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: typeIcon(selectedType))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(typeColor(selectedType))
                }
                .animation(AnimationHelper.quickSpring, value: selectedType)

                // Name
                LimitedTextField(
                    icon: "textformat",
                    placeholder: "Nombre",
                    text: $name,
                    maxLength: 30,
                    focusedField: $nameFocused,
                    fieldValue: true
                )

                // Type picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tipo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(types, id: \.self) { type in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) { selectedType = type }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: typeIcon(type))
                                        .font(.system(size: 16))
                                        .foregroundStyle(selectedType == type ? .white : typeColor(type))
                                    Text(typeName(type))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedType == type ? .white : .primary)
                                    Spacer()
                                }
                                .padding(AppConstants.UserInterface.padding)
                                .background(selectedType == type ? typeColor(type) : Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditMode ? "Editar método" : "Nuevo método")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await save() }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
        .onAppear {
            if let pm = methodToEdit {
                name = pm.name
                selectedType = pm.type
            }
            nameFocused = true
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let pm = methodToEdit {
            let success = await viewModel.updatePaymentMethod(paymentMethodId: pm.id, name: trimmed, type: selectedType)
            if success { onSaved(); dismiss() }
        } else {
            let success = await viewModel.createPaymentMethod(name: trimmed, type: selectedType, groupId: group.id)
            if success { onSaved(); dismiss() }
        }
    }

    private func typeIcon(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return "banknote.fill" }
        if t.contains("transfer") { return "arrow.left.arrow.right" }
        if t.contains("digital") || t.contains("wallet") { return "iphone" }
        return "creditcard.fill"
    }

    private func typeColor(_ type: String) -> Color {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return .green }
        if t.contains("transfer") { return .orange }
        if t.contains("digital") || t.contains("wallet") { return .purple }
        return .blue
    }

    private func typeName(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("cash") || t.contains("efectivo") { return "Efectivo" }
        if t.contains("transfer") { return "Transferencia" }
        if t.contains("digital") || t.contains("wallet") { return "Digital" }
        if t.contains("debit") { return "Débito" }
        return type.isEmpty ? "Tarjeta" : type
    }
}
