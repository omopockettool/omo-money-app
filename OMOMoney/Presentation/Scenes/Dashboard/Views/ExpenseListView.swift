//
//  ExpenseListView.swift
//  OMOMoney
//

import SwiftUI

struct ExpenseListView<EmptyState: View>: View {
    @Binding private var collapsedDays: Set<Date>

    let itemLists: [SDItemList]
    let getFormattedAmount: (SDItemList) -> String
    let getFormattedUnpaidAmount: (SDItemList) -> String?
    let getSearchSummary: (SDItemList) -> String?
    let getSearchMatchedSubtotal: (SDItemList) -> String?
    let getSearchMatchedUnpaid: (SDItemList) -> String?
    let itemListRowStatus: [UUID: ItemListRowStatus]
    let onItemTap: (SDItemList) -> Void
    let onTogglePaid: (SDItemList) -> Void
    let onRefresh: () async -> Void
    let onDelete: (SDItemList) async -> Void
    let customEmptyState: EmptyState
    let showCustomEmptyState: Bool
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
        getSearchSummary: @escaping (SDItemList) -> String? = { _ in nil },
        getSearchMatchedSubtotal: @escaping (SDItemList) -> String? = { _ in nil },
        getSearchMatchedUnpaid: @escaping (SDItemList) -> String? = { _ in nil },
        itemListRowStatus: [UUID: ItemListRowStatus],
        onItemTap: @escaping (SDItemList) -> Void,
        onTogglePaid: @escaping (SDItemList) -> Void,
        onRefresh: @escaping () async -> Void,
        onDelete: @escaping (SDItemList) async -> Void,
        @ViewBuilder customEmptyState: () -> EmptyState,
        showCustomEmptyState: Bool = true,
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
        self.getSearchSummary = getSearchSummary
        self.getSearchMatchedSubtotal = getSearchMatchedSubtotal
        self.getSearchMatchedUnpaid = getSearchMatchedUnpaid
        self.itemListRowStatus = itemListRowStatus
        self.onItemTap = onItemTap
        self.onTogglePaid = onTogglePaid
        self.onRefresh = onRefresh
        self.onDelete = onDelete
        self.customEmptyState = customEmptyState()
        self.showCustomEmptyState = showCustomEmptyState
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
            if itemLists.isEmpty && showCustomEmptyState {
                customEmptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if itemLists.isEmpty && !showCustomEmptyState {
                ExpenseListEmptyState()
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
        .if(!isCompact) {
            $0.refreshable {
                await onRefresh()
                try? await Task.sleep(for: .milliseconds(180))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func itemListRow(_ itemList: SDItemList, timelinePosition: TimelinePosition) -> some View {
        ExpenseListRowContainer(
            itemList: itemList,
            formattedAmount: getFormattedAmount(itemList),
            formattedUnpaidAmount: getFormattedUnpaidAmount(itemList),
            searchSummary: getSearchSummary(itemList),
            searchMatchedSubtotal: getSearchMatchedSubtotal(itemList),
            searchMatchedUnpaid: getSearchMatchedUnpaid(itemList),
            rowStatus: itemListRowStatus[itemList.id] ?? .neutral,
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

// MARK: - Convenience init (no custom empty state)
extension ExpenseListView where EmptyState == EmptyView {
    init(
        itemLists: [SDItemList],
        getFormattedAmount: @escaping (SDItemList) -> String,
        getFormattedUnpaidAmount: @escaping (SDItemList) -> String?,
        getSearchSummary: @escaping (SDItemList) -> String? = { _ in nil },
        getSearchMatchedSubtotal: @escaping (SDItemList) -> String? = { _ in nil },
        getSearchMatchedUnpaid: @escaping (SDItemList) -> String? = { _ in nil },
        itemListRowStatus: [UUID: ItemListRowStatus],
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
        self.init(
            itemLists: itemLists,
            getFormattedAmount: getFormattedAmount,
            getFormattedUnpaidAmount: getFormattedUnpaidAmount,
            getSearchSummary: getSearchSummary,
            getSearchMatchedSubtotal: getSearchMatchedSubtotal,
            getSearchMatchedUnpaid: getSearchMatchedUnpaid,
            itemListRowStatus: itemListRowStatus,
            onItemTap: onItemTap,
            onTogglePaid: onTogglePaid,
            onRefresh: onRefresh,
            onDelete: onDelete,
            customEmptyState: { EmptyView() },
            showCustomEmptyState: false,
            isCompact: isCompact,
            getDayTotal: getDayTotal,
            focusedDate: focusedDate,
            hideSectionHeaders: hideSectionHeaders,
            onAddForDate: onAddForDate,
            collapsedDays: collapsedDays,
            allowsDayCollapse: allowsDayCollapse
        )
    }
}

// MARK: - Preview
#Preview {
    ExpenseListView(
        itemLists: [],
        getFormattedAmount: { _ in "12,89 €" },
        getFormattedUnpaidAmount: { _ in nil },
        itemListRowStatus: [:],
        onItemTap: { _ in },
        onTogglePaid: { _ in },
        onRefresh: { },
        onDelete: { _ in }
    )
    .background(Color.black)
}
