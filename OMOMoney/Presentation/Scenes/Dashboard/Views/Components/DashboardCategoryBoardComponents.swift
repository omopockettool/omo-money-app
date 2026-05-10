import SwiftUI

struct DashboardCategoryBoardView<EmptyState: View>: View {
    let boxes: [DashboardCategoryBoxData]
    let allFormattedAmount: String
    let allFormattedUnpaidAmount: String?
    let getFormattedAmount: (DashboardCategoryBoxData) -> String
    let getFormattedUnpaidAmount: (DashboardCategoryBoxData) -> String?
    let onRefresh: () async -> Void
    let customEmptyState: EmptyState
    let showCustomEmptyState: Bool
    let onSelectAll: () -> Void
    let onSelect: (DashboardCategoryBoxData) -> Void

    init(
        boxes: [DashboardCategoryBoxData],
        allFormattedAmount: String,
        allFormattedUnpaidAmount: String?,
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        getFormattedUnpaidAmount: @escaping (DashboardCategoryBoxData) -> String?,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder customEmptyState: () -> EmptyState,
        showCustomEmptyState: Bool = true,
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (DashboardCategoryBoxData) -> Void
    ) {
        self.boxes = boxes
        self.allFormattedAmount = allFormattedAmount
        self.allFormattedUnpaidAmount = allFormattedUnpaidAmount
        self.getFormattedAmount = getFormattedAmount
        self.getFormattedUnpaidAmount = getFormattedUnpaidAmount
        self.onRefresh = onRefresh
        self.customEmptyState = customEmptyState()
        self.showCustomEmptyState = showCustomEmptyState
        self.onSelectAll = onSelectAll
        self.onSelect = onSelect
    }

    private let rowSpacing: CGFloat = 12
    private let columnSpacing: CGFloat = 12

    var body: some View {
        ScrollView {
            if boxes.isEmpty && showCustomEmptyState {
                customEmptyState
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            } else if boxes.isEmpty && !showCustomEmptyState {
                DashboardCategoryBoardEmptyState()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 72)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            } else {
                VStack(spacing: rowSpacing) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { indexedRow in
                        rowView(indexedRow.element)
                    }

                    if !boxes.isEmpty {
                        DashboardAllCategoryBoxView(
                            onTap: onSelectAll
                        )
                    }
                }
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, AppConstants.UserInterface.padding)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        .refreshable {
            await onRefresh()
            try? await Task.sleep(for: .milliseconds(180))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func rowView(_ row: DashboardCategoryBoardRow) -> some View {
        switch row {
        case .single(let box):
            DashboardCategoryBoxView(
                data: box,
                formattedAmount: getFormattedAmount(box),
                formattedUnpaidAmount: getFormattedUnpaidAmount(box),
                onTap: { onSelect(box) }
            )
        case .pair(let leading, let trailing):
            HStack(alignment: .top, spacing: columnSpacing) {
                DashboardCategoryBoxView(
                    data: leading,
                    formattedAmount: getFormattedAmount(leading),
                    formattedUnpaidAmount: getFormattedUnpaidAmount(leading),
                    onTap: { onSelect(leading) }
                )

                DashboardCategoryBoxView(
                    data: trailing,
                    formattedAmount: getFormattedAmount(trailing),
                    formattedUnpaidAmount: getFormattedUnpaidAmount(trailing),
                    onTap: { onSelect(trailing) }
                )
            }
        }
    }

    private var rows: [DashboardCategoryBoardRow] {
        DashboardCategoryBoxGridLayout.makeRows(from: boxes)
    }
}

// MARK: - Convenience init (no custom empty state)
extension DashboardCategoryBoardView where EmptyState == EmptyView {
    init(
        boxes: [DashboardCategoryBoxData],
        allFormattedAmount: String,
        allFormattedUnpaidAmount: String?,
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        getFormattedUnpaidAmount: @escaping (DashboardCategoryBoxData) -> String?,
        onRefresh: @escaping () async -> Void,
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (DashboardCategoryBoxData) -> Void
    ) {
        self.init(
            boxes: boxes,
            allFormattedAmount: allFormattedAmount,
            allFormattedUnpaidAmount: allFormattedUnpaidAmount,
            getFormattedAmount: getFormattedAmount,
            getFormattedUnpaidAmount: getFormattedUnpaidAmount,
            onRefresh: onRefresh,
            customEmptyState: { EmptyView() },
            showCustomEmptyState: false,
            onSelectAll: onSelectAll,
            onSelect: onSelect
        )
    }
}

private struct DashboardAllCategoryBoxView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .semibold))

                Text(LocalizationKey.General.all.localized)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.white.opacity(0.96))
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .fill(Color(.systemGray).opacity(0.9))
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(PressHapticButtonStyle())
    }
}

private enum DashboardCategoryBoardRow {
    case single(DashboardCategoryBoxData)
    case pair(DashboardCategoryBoxData, DashboardCategoryBoxData)
}

private enum DashboardCategoryBoxGridLayout {
    static func makeRows(from boxes: [DashboardCategoryBoxData]) -> [DashboardCategoryBoardRow] {
        var rows: [DashboardCategoryBoardRow] = []
        var index = 0

        while index < boxes.count {
            let current = boxes[index]

            if current.sizeTier == .large {
                rows.append(.single(current))
                index += 1
                continue
            }

            let nextIndex = index + 1
            if nextIndex < boxes.count, boxes[nextIndex].sizeTier != .large {
                rows.append(.pair(current, boxes[nextIndex]))
                index += 2
            } else {
                rows.append(.single(current))
                index += 1
            }
        }

        return rows
    }
}

struct DashboardCategoryBoxView: View {
    let data: DashboardCategoryBoxData
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let onTap: () -> Void

    private var accentColor: Color {
        Color(hex: data.categoryColorHex) ?? .accentColor
    }

    private var minHeight: CGFloat {
        switch data.sizeTier {
        case .small:
            72
        case .medium:
            88
        case .large:
            98
        }
    }

    private var titleFont: Font {
        switch data.sizeTier {
        case .small:
            .subheadline.weight(.semibold)
        case .medium:
            .headline.weight(.semibold)
        case .large:
            .title3.weight(.bold)
        }
    }

    private var amountFont: Font {
        switch data.sizeTier {
        case .small:
            .title3.weight(.bold)
        case .medium:
            .title2.weight(.bold)
        case .large:
            .system(size: 28, weight: .bold, design: .rounded)
        }
    }

    private var horizontalPadding: CGFloat {
        switch data.sizeTier {
        case .small:
            14
        case .medium:
            15
        case .large:
            18
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: data.categoryIcon)
                            .font(.system(size: 14, weight: .semibold))

                        Text(data.categoryName)
                            .font(titleFont)
                            .lineLimit(data.sizeTier == .large ? 2 : 1)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(accentColor)

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedAmount)
                        .font(amountFont)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let formattedUnpaidAmount {
                        Text("\(formattedUnpaidAmount) \(LocalizationKey.Item.unpaid.localized)")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .fill(accentColor.opacity(0.13))
            }
        }
        .buttonStyle(PressHapticButtonStyle())
    }
}

struct DashboardCategoryBoardEmptyState: View {
    var body: some View {
        EmptyStateView(message: LocalizationKey.Entry.tapToAdd.localized)
    }
}
