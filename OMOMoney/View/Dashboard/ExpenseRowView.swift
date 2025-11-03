//
//  ExpenseRowView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct ExpenseRowView: View {
    let itemList: ItemList
    let formattedAmount: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.UserInterface.padding) {
                // Check mark circle
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                // Content area
                VStack(alignment: .leading, spacing: 4) {
                    // ItemList description
                    Text(itemList.itemListDescription ?? "Sin descripción")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Category tag
                    if let category = getFirstCategory() {
                        Text(category.name ?? "Sin categoría")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                            .padding(.vertical, 4)
                            .background(getCategoryColor(category))
                            .cornerRadius(AppConstants.UserInterface.cornerRadius / 2)
                    }
                }
                
                Spacer()
                
                // Amount
                Text(formattedAmount)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.systemGray5))
            .cornerRadius(AppConstants.UserInterface.cornerRadius)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    /// Get the category from the ItemList (each ItemList has one category)
    private func getFirstCategory() -> Category? {
        return itemList.category
    }
    
    /// Get the color for a category
    private func getCategoryColor(_ category: Category) -> Color {
        guard let colorString = category.color else {
            return Color.gray
        }
        return Color(hex: colorString) ?? Color.gray
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 10) {
        // Preview with sample data
        ExpenseRowView(
            itemList: {
                let context = PersistenceController.preview.container.viewContext
                let itemList = ItemList(context: context)
                itemList.itemListDescription = "Compras del supermercado"
                itemList.date = Date()
                
                let group = Group(context: context)
                group.name = "Compras Ahorramas"
                group.currency = "EUR"
                itemList.group = group
                
                return itemList
            }(),
            formattedAmount: "12.89 €",
            onTap: {
                print("Expense row tapped")
            }
        )
        
        ExpenseRowView(
            itemList: {
                let context = PersistenceController.preview.container.viewContext
                let itemList = ItemList(context: context)
                itemList.itemListDescription = "Cena en restaurante"
                itemList.date = Date()
                
                let group = Group(context: context)
                group.name = "Gastos Personales"
                group.currency = "EUR"
                itemList.group = group
                
                return itemList
            }(),
            formattedAmount: "45.60 €",
            onTap: {
                print("Expense row tapped")
            }
        )
    }
    .padding()
    .background(Color.black)
}