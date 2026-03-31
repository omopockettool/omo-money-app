//
//  ExpenseListView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct ExpenseListView: View {
    let itemLists: [ItemListDomain]
    let getFormattedAmount: (ItemListDomain) -> String
    let itemListCounts: [UUID: Int]
    let categories: [UUID: (name: String, color: String)]
    let onItemTap: (ItemListDomain) -> Void
    let onRefresh: () async -> Void
    let onDelete: (ItemListDomain) async -> Void
    
    var body: some View {
        List {
            if itemLists.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                // Lista normal - lo más reciente arriba
                ForEach(groupedItemLists.keys.sorted(by: >), id: \.self) { date in
                    if let itemListsForDate = groupedItemLists[date] {
                        Section {
                            ForEach(itemListsForDate, id: \.id) { itemList in
                                ExpenseRowView(
                                    itemList: itemList,
                                    formattedAmount: getFormattedAmount(itemList),
                                    itemCount: itemListCounts[itemList.id] ?? 0,
                                    categoryName: itemList.categoryId.flatMap { categories[$0]?.name },
                                    categoryColor: itemList.categoryId.flatMap { categories[$0]?.color }.flatMap { Color(hex: $0) },
                                    onTap: { onItemTap(itemList) }
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
                                        Task {
                                            await onDelete(itemList)
                                        }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            sectionHeader(for: date)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.2), value: itemLists.count)
        .refreshable {
            await onRefresh()
        }
    }
    
    // MARK: - Private Views
    
    private var emptyStateView: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No hay gastos")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Pulsa el botón + para agregar tu primer gasto")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
    
    private func sectionHeader(for date: Date) -> some View {
        Text(formatSectionDate(date))
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
    
    // MARK: - Helper Methods

    /// Group ItemLists by date for sectioned display
    private var groupedItemLists: [Date: [ItemListDomain]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: itemLists) { itemList in
            calendar.startOfDay(for: itemList.date)
        }
        return grouped
    }
    
    /// Format date for section headers
    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoy"
        } else if calendar.isDateInYesterday(date) {
            return "Ayer"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview
#Preview {
    ExpenseListView(
        itemLists: [],
        getFormattedAmount: { _ in "12,89 €" },
        itemListCounts: [:],
        categories: [:],
        onItemTap: { _ in },
        onRefresh: { },
        onDelete: { _ in }
    )
    .background(Color.black)
}