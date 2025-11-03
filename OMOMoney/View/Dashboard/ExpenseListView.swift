//
//  ExpenseListView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct ExpenseListView: View {
    let itemLists: [ItemList]
    let getFormattedAmount: (ItemList) -> String
    let onItemTap: (ItemList) -> Void
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppConstants.UserInterface.smallPadding) {
                if itemLists.isEmpty {
                    emptyStateView
                } else {
                    ForEach(groupedItemLists.keys.sorted(by: >), id: \.self) { date in
                        if let itemListsForDate = groupedItemLists[date] {
                            // Date section header
                            sectionHeader(for: date)
                            
                            // Items for this date
                            ForEach(itemListsForDate, id: \.objectID) { itemList in
                                ExpenseRowView(
                                    itemList: itemList,
                                    formattedAmount: getFormattedAmount(itemList),
                                    onTap: {
                                        onItemTap(itemList)
                                    }
                                )
                                .padding(.horizontal, AppConstants.UserInterface.padding)
                            }
                        }
                    }
                }
            }
            .padding(.top, AppConstants.UserInterface.smallPadding)
        }
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
        .padding(.top, 50)
    }
    
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(formatSectionDate(date))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.padding)
    }
    
    // MARK: - Helper Methods
    
    /// Group ItemLists by date for sectioned display
    private var groupedItemLists: [Date: [ItemList]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: itemLists) { itemList in
            calendar.startOfDay(for: itemList.date ?? Date())
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
        getFormattedAmount: { _ in "12.89 €" },
        onItemTap: { _ in },
        onRefresh: { }
    )
    .background(Color.black)
}