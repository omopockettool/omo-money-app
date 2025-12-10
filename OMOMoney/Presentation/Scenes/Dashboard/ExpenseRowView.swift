//
//  ExpenseRowView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct ExpenseRowView: View {
    let itemList: ItemListDomain
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
                    Text(itemList.itemListDescription)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()
                    
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
    /// TODO: Implement proper category fetching via Use Case using categoryId
    private func getFirstCategory() -> Category? {
        return nil  // Domain model only has categoryId, not category relationship
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
            itemList: ItemListDomain(
                id: UUID(),
                itemListDescription: "Compras del supermercado",
                date: Date(),
                categoryId: UUID(),
                paymentMethodId: UUID(),
                groupId: UUID(),
                createdAt: Date(),
                lastModifiedAt: nil
            ),
            formattedAmount: "12.89 €",
            onTap: {
                print("Expense row tapped")
            }
        )

        ExpenseRowView(
            itemList: ItemListDomain(
                id: UUID(),
                itemListDescription: "Cena en restaurante",
                date: Date(),
                categoryId: UUID(),
                paymentMethodId: UUID(),
                groupId: UUID(),
                createdAt: Date(),
                lastModifiedAt: nil
            ),
            formattedAmount: "45.60 €",
            onTap: {
                print("Expense row tapped")
            }
        )
    }
    .padding()
    .background(Color.black)
}