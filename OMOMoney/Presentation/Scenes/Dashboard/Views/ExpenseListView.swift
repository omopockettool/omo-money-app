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
            } else if hideSectionHeaders {
                ForEach(Array(itemLists.enumerated()), id: \.element.id) { index, itemList in
                    itemListRow(
                        itemList,
                        timelinePosition: timelinePosition(
                            index: index,
                            count: itemLists.count
                        )
                    )
                }
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
        .scrollIndicators(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        .if(!isCompact) { $0.refreshable { await onRefresh() } }
    }

    @ViewBuilder
    private func itemListRow(_ itemList: SDItemList, timelinePosition: TimelinePosition) -> some View {
        let categoryName = itemList.category.flatMap { categories[$0.id]?.name }
        let categoryColor = itemList.category.flatMap { categories[$0.id]?.color }.flatMap { Color(hex: $0) }
        let categoryIcon = itemList.category.flatMap { categories[$0.id]?.icon }
        ExpenseListRowContainer(
            itemList: itemList,
            formattedAmount: getFormattedAmount(itemList),
            formattedUnpaidAmount: getFormattedUnpaidAmount(itemList),
            itemCount: itemListCounts[itemList.id] ?? 0,
            categoryName: categoryName,
            categoryColor: categoryColor,
            categoryIcon: categoryIcon,
            paidStatus: itemListPaidStatus[itemList.id] ?? .none,
            isCompact: isCompact,
            timelinePosition: timelinePosition,
            onTap: { onItemTap(itemList) },
            onTogglePaid: { onTogglePaid(itemList) },
            onDelete: {
                Task { await onDelete(itemList) }
            }
        )
    }
    
    // MARK: - Private Views
    
    private var emptyStateView: some View {
        ExpenseListEmptyState()
    }
    
    @ViewBuilder
    private func sectionHeader(for date: Date) -> some View {
        ExpenseListSectionHeader(
            date: date,
            isCompact: isCompact,
            hideSectionHeaders: hideSectionHeaders,
            allowsDayCollapse: allowsDayCollapse,
            isCollapsed: isCollapsed(date),
            total: getDayTotal?(date),
            onToggleCollapsed: {
                guard allowsDayCollapse else { return }
                toggleCollapsed(date)
            }
        )
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
