//
//  ExpenseListView.swift
//  OMOMoney
//

import SwiftUI

struct ExpenseListView: View {
    @Binding private var collapsedDays: Set<Date>

    let itemLists: [SDItemList]
    let getFormattedAmount: (SDItemList) -> String
    let getFormattedUnpaidAmount: (SDItemList) -> String?
    let itemListCounts: [UUID: Int]
    let categories: [UUID: (name: String, color: String, icon: String)]
    let itemListPaidStatus: [UUID: ItemListPaidStatus]
    let onItemTap: (SDItemList) -> Void
    let onTogglePaid: (SDItemList) -> Void
    let onRefresh: () async -> Void
    let onDelete: (SDItemList) async -> Void
    var isCompact: Bool = false
    var getDayTotal: ((Date) -> String)? = nil
    var focusedDate: Date? = nil
    var hideSectionHeaders: Bool = false
    var onAddForDate: ((Date) -> Void)? = nil
    var allowsDayCollapse: Bool = false

    init(
        itemLists: [SDItemList],
        getFormattedAmount: @escaping (SDItemList) -> String,
        getFormattedUnpaidAmount: @escaping (SDItemList) -> String?,
        itemListCounts: [UUID: Int],
        categories: [UUID: (name: String, color: String, icon: String)],
        itemListPaidStatus: [UUID: ItemListPaidStatus],
        onItemTap: @escaping (SDItemList) -> Void,
        onTogglePaid: @escaping (SDItemList) -> Void,
        onRefresh: @escaping () async -> Void,
        onDelete: @escaping (SDItemList) async -> Void,
        isCompact: Bool = false,
        getDayTotal: ((Date) -> String)? = nil,
        focusedDate: Date? = nil,
        hideSectionHeaders: Bool = false,
        onAddForDate: ((Date) -> Void)? = nil,
        collapsedDays: Binding<Set<Date>> = .constant([]),
        allowsDayCollapse: Bool = false
    ) {
        self.itemLists = itemLists
        self.getFormattedAmount = getFormattedAmount
        self.getFormattedUnpaidAmount = getFormattedUnpaidAmount
        self.itemListCounts = itemListCounts
        self.categories = categories
        self.itemListPaidStatus = itemListPaidStatus
        self.onItemTap = onItemTap
        self.onTogglePaid = onTogglePaid
        self.onRefresh = onRefresh
        self.onDelete = onDelete
        self.isCompact = isCompact
        self.getDayTotal = getDayTotal
        self.focusedDate = focusedDate
        self.hideSectionHeaders = hideSectionHeaders
        self.onAddForDate = onAddForDate
        self._collapsedDays = collapsedDays
        self.allowsDayCollapse = allowsDayCollapse
    }
    
    var body: some View {
        List {
            if itemLists.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(groupedItemLists.keys.sorted(by: >), id: \.self) { date in
                    if let itemListsForDate = groupedItemLists[date] {
                        Section {
                            if !isCollapsed(date) {
                                ForEach(Array(itemListsForDate.enumerated()), id: \.element.id) { index, itemList in
                                    itemListRow(
                                        itemList,
                                        timelinePosition: timelinePosition(
                                            index: index,
                                            count: itemListsForDate.count
                                        )
                                    )
                                }
                            }
                        } header: {
                            sectionHeader(for: date)
                        }
                        .opacity(sectionOpacity(for: date))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .if(!isCompact) { $0.refreshable { await onRefresh() } }
    }

    @ViewBuilder
    private func itemListRow(_ itemList: SDItemList, timelinePosition: TimelinePosition) -> some View {
        let categoryName = itemList.category.flatMap { categories[$0.id]?.name }
        let categoryColor = itemList.category.flatMap { categories[$0.id]?.color }.flatMap { Color(hex: $0) }
        let categoryIcon = itemList.category.flatMap { categories[$0.id]?.icon }
        ExpenseRowView(
            itemList: itemList,
            formattedAmount: getFormattedAmount(itemList),
            formattedUnpaidAmount: getFormattedUnpaidAmount(itemList),
            itemCount: itemListCounts[itemList.id] ?? 0,
            categoryName: categoryName,
            categoryColor: categoryColor,
            categoryIcon: categoryIcon,
            paidStatus: itemListPaidStatus[itemList.id] ?? .none,
            onTap: { onItemTap(itemList) },
            onTogglePaid: { onTogglePaid(itemList) },
            isCompact: isCompact,
            timelinePosition: timelinePosition
        )
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: AppConstants.UserInterface.smallPadding,
            bottom: 0,
            trailing: AppConstants.UserInterface.padding
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await onDelete(itemList) }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Private Views
    
    private var emptyStateView: some View {
        EmptyStateView(message: "Pulsa el + para agregar un registro")
    }
    
    @ViewBuilder
    private func sectionHeader(for date: Date) -> some View {
        if !isCompact && !hideSectionHeaders {
            HStack(spacing: 8) {
                Button {
                    guard allowsDayCollapse else { return }
                    toggleCollapsed(date)
                } label: {
                    HStack(spacing: 8) {
                        if allowsDayCollapse {
                            Image(systemName: isCollapsed(date) ? "chevron.right" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 12)
                        }
                        Text(DateFormatterHelper.formatSectionDate(date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        if let total = getDayTotal?(date) {
                            Text(total)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.none)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!allowsDayCollapse)

                if let onAdd = onAddForDate {
                    Menu {
                        Button {
                            onAdd(date)
                        } label: {
                            Label("Añadir en esta fecha", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods

    private func sectionOpacity(for date: Date) -> Double {
        guard let focused = focusedDate else { return 1.0 }
        return Calendar.current.isDate(date, inSameDayAs: focused) ? 1.0 : 0.4
    }

    private func isCollapsed(_ date: Date) -> Bool {
        collapsedDays.contains(Calendar.current.startOfDay(for: date))
    }

    private func toggleCollapsed(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        withAnimation(AnimationHelper.quickEase) {
            if collapsedDays.contains(day) {
                collapsedDays.remove(day)
            } else {
                collapsedDays.insert(day)
            }
        }
    }

    private var groupedItemLists: [Date: [SDItemList]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: itemLists) { itemList in
            calendar.startOfDay(for: itemList.date)
        }
        return grouped
    }

    private func timelinePosition(index: Int, count: Int) -> TimelinePosition {
        if count == 1 { return .single }
        if index == 0 { return .first }
        if index == count - 1 { return .last }
        return .middle
    }
    
}

// MARK: - Preview
#Preview {
    ExpenseListView(
        itemLists: [],
        getFormattedAmount: { _ in "12,89 €" },
        getFormattedUnpaidAmount: { _ in nil },
        itemListCounts: [:],
        categories: [:],
        itemListPaidStatus: [:],
        onItemTap: { _ in },
        onTogglePaid: { _ in },
        onRefresh: { },
        onDelete: { _ in }
    )
    .background(Color.black)
}
