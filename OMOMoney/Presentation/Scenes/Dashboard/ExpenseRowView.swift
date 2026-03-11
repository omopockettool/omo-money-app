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
    let itemCount: Int
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppConstants.UserInterface.padding) {
            // Check mark circle
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            // Content area
            VStack(alignment: .leading, spacing: 12) {
                // Top row: description + amount
                HStack(alignment: .firstTextBaseline) {
                    Text(itemList.itemListDescription)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(formattedAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)
                }

                // Bottom row: item count (left) + chevron (right)
                HStack {
                    Text(itemCount == 1 ? "1 artículo" : "\(itemCount) artículos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.systemGray5))
        .cornerRadius(AppConstants.UserInterface.cornerRadius)
        .contentShape(Rectangle())  // ✅ FIX: Define explicit tap area
        .onTapGesture {  // ✅ FIX: Use onTapGesture instead of Button for better swipe discrimination
            onTap()
        }
    }
    
}

// MARK: - Preview
#Preview {
    VStack(spacing: 10) {
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
            formattedAmount: "12,89 €",
            itemCount: 1,
            onTap: {}
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
            formattedAmount: "45,60 €",
            itemCount: 3,
            onTap: {}
        )
    }
    .padding()
    .background(Color.black)
}