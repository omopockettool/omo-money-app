import SwiftUI
import OSLog

struct GroupInfoEditSheet: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GroupFormViewModel()
    @State private var debugNodeID = UUID()
    @State private var name = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var nameFocused: Bool?

    private var availableCurrencies: [(String, String)] {
        [
            ("EUR", LocalizationKey.Group.currencyEuro.localized),
            ("USD", LocalizationKey.Group.currencyDollar.localized)
        ]
    }

    private static let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.GroupInfoEditSheet")

    init(group: SDGroup, onSaved: @escaping () -> Void) {
        self.group = group
        self.onSaved = onSaved

        _name = State(wrappedValue: group.name)
        _selectedCurrency = State(wrappedValue: group.currency)
        Self.logger.debug("init initialName=\(group.name) initialCurrency=\(group.currency)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: LocalizationKey.Group.name.localized,
                        text: $name,
                        maxLength: 30,
                        focusedField: $nameFocused,
                        fieldValue: true
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizationKey.Group.currency.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(availableCurrencies, id: \.0) { code, label in
                                Button {
                                    withAnimation(AnimationHelper.quickSpring) { selectedCurrency = code }
                                } label: {
                                    HStack {
                                        Text(label)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedCurrency == code {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                    .padding(AppConstants.UserInterface.padding)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if code != availableCurrencies.last?.0 {
                                    Divider()
                                        .padding(.horizontal, AppConstants.UserInterface.padding)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                    }
                }
                .padding(AppConstants.UserInterface.padding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizationKey.Group.info.localized)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                Self.logger.debug("node appeared nodeID=\(self.debugNodeID.uuidString) draftName=\(self.name) currency=\(self.selectedCurrency)")
            }
            .onDisappear {
                Self.logger.debug("node disappeared nodeID=\(self.debugNodeID.uuidString) draftName=\(self.name) currency=\(self.selectedCurrency)")
            }
            .onChange(of: name) { _, newValue in
                Self.logger.debug("draft name changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
            }
            .onChange(of: selectedCurrency) { _, newValue in
                Self.logger.debug("draft currency changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Self.logger.debug("save tapped trimmedName=\(trimmed) selectedCurrency=\(selectedCurrency)")
        if await viewModel.update(group: group, name: trimmed, currency: selectedCurrency) {
            Self.logger.debug("save succeeded")
            onSaved()
            dismiss()
        } else {
            Self.logger.debug("save failed")
        }
    }
}
