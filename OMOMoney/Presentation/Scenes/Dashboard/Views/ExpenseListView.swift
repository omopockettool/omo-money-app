//
//  ExpenseListView.swift
//  OMOMoney
//

import SwiftUI

struct ExpenseListView: View {
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
                            ForEach(itemListsForDate, id: \.id) { itemList in
                                itemListRow(itemList)
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
    private func itemListRow(_ itemList: SDItemList) -> some View {
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
            isCompact: isCompact
        )
        .listRowInsets(EdgeInsets(
            top: AppConstants.UserInterface.smallPadding / 2,
            leading: AppConstants.UserInterface.padding,
            bottom: AppConstants.UserInterface.smallPadding / 2,
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
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "sparkles.2")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Nada por aquí...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pulsa el + para agregar un registro")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private func sectionHeader(for date: Date) -> some View {
        if !isCompact && !hideSectionHeaders {
            HStack(spacing: 8) {
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

    private var groupedItemLists: [Date: [SDItemList]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: itemLists) { itemList in
            calendar.startOfDay(for: itemList.date)
        }
        return grouped
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
