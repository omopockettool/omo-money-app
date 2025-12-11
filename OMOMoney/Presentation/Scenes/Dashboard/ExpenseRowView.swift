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
    let categoryName: String?  // ✅ NEW: Pass category info from parent
    let categoryColor: String?  // ✅ NEW: Pass category color from parent
    let onTap: () -> Void

    var body: some View {
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
                if let categoryName = categoryName {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                        .padding(.vertical, 4)
                        .background(getCategoryColorFromHex())
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
        .contentShape(Rectangle())  // ✅ FIX: Define explicit tap area
        .onTapGesture {  // ✅ FIX: Use onTapGesture instead of Button for better swipe discrimination
            onTap()
        }
    }
    
    // MARK: - Helper Methods

    /// Get the color from hex string
    private func getCategoryColorFromHex() -> Color {
        guard let colorString = categoryColor else {
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
            categoryName: "Hogar",
            categoryColor: "#4CAF50",
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
            categoryName: "Alimentación",
            categoryColor: "#FF9800",
            onTap: {
                print("Expense row tapped")
            }
        )
    }
    .padding()
    .background(Color.black)
}