import SwiftUI

enum AddItemField {
    case description
    case amount
    case quantity
}

struct AddItemView: View {
    let onItemSaved: (SDItem) -> Void
    let currencyCode: String
    let itemListDescription: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddItemViewModel
    @FocusState private var focusedField: AddItemField?
    @State private var displayedSubtotal: String = ""
    @State private var subtotalIsDecreasing: Bool = false

    init(
        itemListId: UUID,
        itemToEdit: SDItem? = nil,
        itemListDescription: String,
        itemListDate: Date,
        currencyCode: String = "EUR",
        onItemSaved: @escaping (SDItem) -> Void,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.onItemSaved = onItemSaved
        self.currencyCode = currencyCode
        self.itemListDescription = itemListDescription
        self._viewModel = State(wrappedValue: AddItemViewModel(
            itemListId: itemListId,
            itemToEdit: itemToEdit,
            itemListDescription: itemListDescription,
            itemListDate: itemListDate,
            createItemUseCase: createItemUseCase,
            updateItemUseCase: updateItemUseCase
        ))
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var quantityValue: Int { Int(viewModel.quantity) ?? 1 }

    private var subtotalAmount: String {
        let normalized = viewModel.amount.replacingOccurrences(of: ",", with: ".")
        guard let price = Decimal(string: normalized), price > 0, quantityValue > 1 else { return "" }
        let total = price * Decimal(quantityValue)
        return String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue) + " " + currencySymbol
    }

    private var subtotalFormula: String {
        guard quantityValue > 1 else { return "" }
        return "\(viewModel.amount) \(currencySymbol) × \(quantityValue) \(LocalizationKey.Item.units.localized)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroAmountInput
                    descriptionCard
                    quantityStepper
                    if viewModel.showsTotalPreview {
                        subtotalCard
                    }
                }
                .padding(AppConstants.UserInterface.padding)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditMode ? LocalizationKey.Item.editItem.localized : LocalizationKey.Item.newItem.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if let item = await viewModel.saveItem() {
                                onItemSaved(item)
                                dismiss()
                            }
                        }
                    } label: { Image(systemName: "checkmark") }
                    .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizationKey.General.done.localized) { focusedField = nil }
                }
            }
        }
    }

    private var heroAmountInput: some View {
        HeroAmountInputView(
            text: $viewModel.amount,
            currencySymbol: currencySymbol,
            onValidate: viewModel.validateAndCorrectAmount,
            focusedField: $focusedField,
            fieldValue: .amount
        )
    }

    private var descriptionCard: some View {
        LimitedTextField(
            icon: "text.alignleft",
            placeholder: itemListDescription,
            text: $viewModel.description,
            maxLength: 200,
            axis: .vertical,
            focusedField: $focusedField,
            fieldValue: .description
        )
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { max(1, Int(viewModel.quantity) ?? 1) },
            set: { viewModel.quantity = String($0) }
        )
    }

    private var quantityStepper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationKey.Item.quantity.localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                Image(systemName: "number")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                TextField("1", text: $viewModel.quantity)
                    .keyboardType(.numberPad)
                    .font(.subheadline.weight(.semibold))
                    .focused($focusedField, equals: .quantity)
                    .onChange(of: viewModel.quantity) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        if let number = Int(digits) {
                            viewModel.quantity = String(min(number, 999999))
                        } else {
                            viewModel.quantity = digits
                        }
                    }

                Stepper("", value: quantityBinding, in: 1...999999)
                    .labelsHidden()
                    .fixedSize()
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                    .stroke(focusedField == .quantity ? Color(.systemGray3) : Color.clear, lineWidth: 1.5)
                    .animation(AnimationHelper.formFocus, value: focusedField == .quantity)
            )
        }
    }

    private var subtotalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizationKey.Item.subtotal.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(subtotalFormula)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(displayedSubtotal.isEmpty ? subtotalAmount : displayedSubtotal)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: subtotalIsDecreasing))
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: displayedSubtotal)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
        .onAppear { displayedSubtotal = subtotalAmount }
        .onChange(of: subtotalAmount) { _, newValue in
            let oldDigits = Int(displayedSubtotal.filter(\.isNumber)) ?? 0
            let newDigits = Int(newValue.filter(\.isNumber)) ?? 0
            subtotalIsDecreasing = newDigits < oldDigits
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                displayedSubtotal = newValue
            }
        }
    }
}
