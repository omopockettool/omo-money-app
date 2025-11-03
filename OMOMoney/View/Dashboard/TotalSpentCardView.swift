//
//  TotalSpentCardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct TotalSpentCardView: View {
    let totalAmount: String
    let onAddExpense: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Gastado")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(totalAmount)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: onAddExpense) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .background(Color(.systemGray5))
        .cornerRadius(AppConstants.UserInterface.cornerRadius)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TotalSpentCardView(
            totalAmount: "1229.89 €",
            onAddExpense: {
                print("Add expense tapped")
            }
        )
        
        TotalSpentCardView(
            totalAmount: "0.00 €",
            onAddExpense: {
                print("Add expense tapped")
            }
        )
    }
    .padding()
    .background(Color.black)
}