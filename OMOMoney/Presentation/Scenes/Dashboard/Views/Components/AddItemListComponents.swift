import SwiftUI

enum AddItemListField {
    case description
    case price
}

struct AddItemListTopCard: View {
    let isEditMode: Bool
    @Binding var price: String
    let currencySymbol: String
    let descriptionPlaceholder: String
    @Binding var description: String
    let suggestions: [ConceptSuggestion]
    let focusedField: FocusState<AddItemListField?>.Binding
    let onValidate: () -> Void
    let onPaste: () -> Void
    let onSuggestionSelected: (ConceptSuggestion) -> Void
    let onClearDescription: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !isEditMode {
                HeroAmountInputView(
                    text: $price,
                    currencySymbol: currencySymbol,
                    onValidate: onValidate,
                    focusedField: focusedField,
                    fieldValue: .price,
                    embedded: true,
                    onPaste: onPaste
                )

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1.5)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            }

            AddItemListDescriptionField(
                isEditMode: isEditMode,
                description: $description,
                placeholder: descriptionPlaceholder,
                focusedField: focusedField,
                onClear: onClearDescription
            )

            if focusedField.wrappedValue == .description && !suggestions.isEmpty {
                ConceptSuggestionChipsView(
                    suggestions: suggestions
                ) { selected in
                    onSuggestionSelected(selected)
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
    }
}

struct AddItemListDescriptionField: View {
    let isEditMode: Bool
    @Binding var description: String
    let placeholder: String
    let focusedField: FocusState<AddItemListField?>.Binding
    let onClear: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "character.cursor.ibeam")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(.tertiaryLabel))

            TextField(placeholder, text: $description)
                .font(isEditMode ? .body : .subheadline)
                .foregroundStyle(isEditMode ? .primary : .secondary)
                .focused(focusedField, equals: .description)
                .submitLabel(.done)
                .onSubmit {
                    focusedField.wrappedValue = nil
                }
                .lineLimit(1)

            if !description.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.tertiaryLabel))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .animation(AnimationHelper.quickEase, value: description.isEmpty)
            }
        }
        .padding(isEditMode ? AppConstants.UserInterface.largePadding : AppConstants.UserInterface.padding)
    }
}

struct AddItemListCategorySection: View {
    let displayedCategories: [SDCategory]
    let overflowCategories: [SDCategory]
    @Binding var showOverflow: Bool
    let compact: Bool
    let selectedCategoryID: UUID?
    let chipMinHeight: CGFloat
    let chipCornerRadius: CGFloat
    let onSelect: (SDCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationKey.Entry.category.localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(displayedCategories) { category in
                    AddItemListCategoryChip(
                        category: category,
                        isSelected: selectedCategoryID == category.id,
                        compact: compact,
                        minHeight: chipMinHeight,
                        cornerRadius: chipCornerRadius,
                        onTap: { onSelect(category) }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .top)))
                }

                if !overflowCategories.isEmpty && !showOverflow {
                    AddItemListCategoryOverflowChip(
                        overflowSelected: overflowCategories.first { $0.id == selectedCategoryID },
                        compact: compact,
                        minHeight: chipMinHeight,
                        cornerRadius: chipCornerRadius,
                        isExpanded: showOverflow
                    ) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            showOverflow.toggle()
                        }
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showOverflow)

            if showOverflow {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showOverflow = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizationKey.Entry.viewLess.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }
}

private struct AddItemListCategoryChip: View {
    let category: SDCategory
    let isSelected: Bool
    let compact: Bool
    let minHeight: CGFloat
    let cornerRadius: CGFloat
    let onTap: () -> Void

    private var chipColor: Color {
        Color(hex: category.color) ?? .accentColor
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white : chipColor)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .opacity(compact ? 1 : 0)
                .scaleEffect(compact ? 1 : 0.85, anchor: .leading)

                VStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : chipColor)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
                .opacity(compact ? 0 : 1)
                .scaleEffect(compact ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: compact ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, compact ? 14 : 12)
            .padding(.vertical, compact ? 12 : 10)
            .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: compact)
        }
        .buttonStyle(.plain)
    }
}

private struct AddItemListCategoryOverflowChip: View {
    let overflowSelected: SDCategory?
    let compact: Bool
    let minHeight: CGFloat
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let onTap: () -> Void

    private var chipColor: Color {
        overflowSelected.flatMap { Color(hex: $0.color) } ?? Color(.systemGray3)
    }

    private var icon: String {
        overflowSelected?.icon ?? "ellipsis.circle.fill"
    }

    private var label: String {
        overflowSelected?.name ?? LocalizationKey.Entry.more.localized
    }

    private var isActive: Bool {
        overflowSelected != nil
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(isActive ? .white : chipColor)
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundStyle(isActive ? .white : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? .white.opacity(0.8) : Color(.tertiaryLabel))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .opacity(compact ? 1 : 0)
                .scaleEffect(compact ? 1 : 0.85, anchor: .leading)

                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isActive ? .white : chipColor)
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? .white : .primary)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isActive ? .white.opacity(0.8) : Color(.tertiaryLabel))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .opacity(compact ? 0 : 1)
                .scaleEffect(compact ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: compact ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, compact ? 14 : 12)
            .padding(.vertical, compact ? 12 : 10)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: compact)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
        }
        .buttonStyle(.plain)
    }
}

struct AddItemListMoreDetailsSection<Content: View>: View {
    let isEditMode: Bool
    @Binding var showDetails: Bool
    let onCollapse: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 16) {
            if !isEditMode {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showDetails.toggle()
                    }
                    if !showDetails {
                        onCollapse()
                    }
                } label: {
                    HStack {
                        Text(LocalizationKey.Entry.moreDetails.localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if isEditMode || showDetails {
                VStack(spacing: 16) {
                    content()
                }
                .transition(isEditMode ? .identity : .opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .animation(isEditMode ? nil : .spring(response: 0.45, dampingFraction: 0.82), value: showDetails)
            }
        }
    }
}

struct AddItemListPaymentMethodSection: View {
    let displayedPaymentMethods: [SDPaymentMethod]
    let overflowPaymentMethods: [SDPaymentMethod]
    @Binding var showOverflow: Bool
    let selectedPaymentMethodID: UUID?
    let colorForType: (String) -> Color
    let iconForMethod: (SDPaymentMethod) -> String
    let onSelect: (SDPaymentMethod) -> Void
    let onToggleOffSelected: () -> Void
    let onCollapseOverflow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationKey.Entry.paymentMethod.localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .id("paymentMethodAnchor")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(displayedPaymentMethods) { method in
                    AddItemListPaymentMethodChip(
                        method: method,
                        isSelected: selectedPaymentMethodID == method.id,
                        color: colorForType(method.type),
                        iconName: iconForMethod(method)
                    ) {
                        if selectedPaymentMethodID == method.id {
                            onToggleOffSelected()
                        } else {
                            onSelect(method)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .top)))
                }

                if !overflowPaymentMethods.isEmpty && !showOverflow {
                    AddItemListPaymentMethodOverflowChip(
                        overflowSelected: overflowPaymentMethods.first { $0.id == selectedPaymentMethodID },
                        isExpanded: showOverflow,
                        colorForType: colorForType,
                        iconForMethod: iconForMethod
                    ) {
                        withAnimation(AnimationHelper.quickSpring) {
                            showOverflow.toggle()
                        }
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showOverflow)

            if showOverflow {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showOverflow = false
                    }
                    onCollapseOverflow()
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizationKey.Entry.viewLess.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }
}

private struct AddItemListPaymentMethodChip: View {
    let method: SDPaymentMethod
    let isSelected: Bool
    let color: Color
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : color)
                Text(method.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AddItemListPaymentMethodOverflowChip: View {
    let overflowSelected: SDPaymentMethod?
    let isExpanded: Bool
    let colorForType: (String) -> Color
    let iconForMethod: (SDPaymentMethod) -> String
    let onTap: () -> Void

    private var chipColor: Color {
        overflowSelected.map { colorForType($0.type) } ?? Color(.systemGray3)
    }

    private var iconName: String {
        overflowSelected.map(iconForMethod) ?? "ellipsis.circle.fill"
    }

    private var label: String {
        overflowSelected?.name ?? LocalizationKey.Entry.more.localized
    }

    private var isActive: Bool {
        overflowSelected != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(isActive ? .white : chipColor)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(isActive ? .white : .primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isActive ? .white.opacity(0.8) : Color(.tertiaryLabel))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(AnimationHelper.quickSpring, value: isExpanded)
        }
        .buttonStyle(.plain)
    }
}

struct AddItemListDateCard: View {
    @Binding var showDatePicker: Bool
    @Binding var calendarExpanded: Bool
    @Binding var date: Date
    let formattedDate: String
    let focusedField: FocusState<AddItemListField?>.Binding
    let onToggleChanged: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    guard showDatePicker else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        calendarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizationKey.Entry.date.localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(Calendar.current.isDateInToday(date) ? LocalizationKey.Dashboard.today.localized : formattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if showDatePicker {
                            Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Toggle("", isOn: $showDatePicker)
                    .labelsHidden()
                    .onChange(of: showDatePicker) { _, on in
                        focusedField.wrappedValue = nil
                        onToggleChanged(on)
                    }
            }
            .padding(AppConstants.UserInterface.padding)

            if showDatePicker && calendarExpanded {
                Divider()
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, AppConstants.UserInterface.smallPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .id("datePickerAnchor")
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: calendarExpanded)
    }
}

struct AddItemListGroupCard: View {
    let activeGroup: SDGroup
    let availableGroups: [SDGroup]
    let onSelect: (SDGroup) -> Void

    var body: some View {
        Menu {
            ForEach(availableGroups, id: \.id) { group in
                Button {
                    withAnimation(AnimationHelper.quickSpring) {
                        onSelect(group)
                    }
                } label: {
                    if group.id == activeGroup.id {
                        Label(group.name, systemImage: "checkmark")
                    } else {
                        Text(group.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
                Text(LocalizationKey.Group.title.localized)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Text(activeGroup.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if availableGroups.count > 1 {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
