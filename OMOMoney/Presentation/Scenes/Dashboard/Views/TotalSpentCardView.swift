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

    @State private var displayedAmount: String = ""
    @State private var isDecreasing: Bool = false
    @State private var flashColor: Color = .clear
    @State private var cardScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Coste de vida mes")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(displayedAmount)
                    .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText(countsDown: isDecreasing))
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: displayedAmount)
            }

            Spacer(minLength: 4)

            Button(action: onAddExpense) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, 12)
        .background(Color(.systemGray5))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                .fill(flashColor)
                .allowsHitTesting(false)
        )
        .cornerRadius(AppConstants.UserInterface.cornerRadius)
        .scaleEffect(cardScale)
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        .onAppear {
            displayedAmount = totalAmount
        }
        .onChange(of: totalAmount) { oldValue, newValue in
            let oldDigits = extractDigits(from: oldValue)
            let newDigits = extractDigits(from: newValue)
            isDecreasing = newDigits < oldDigits
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                displayedAmount = newValue
            }
            let targetColor: Color = isDecreasing ? .red.opacity(0.12) : .green.opacity(0.12)
            withAnimation(.easeIn(duration: 0.12)) { flashColor = targetColor }
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) { flashColor = .clear }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { cardScale = 1.025 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.12)) { cardScale = 1.0 }
        }
    }

    private func extractDigits(from string: String) -> Int {
        Int(string.filter(\.isNumber)) ?? 0
    }

    private var dynamicFontSize: CGFloat {
        let length = totalAmount.count
        switch length {
        case 0...10:  return 24
        case 11...15: return 20
        case 16...20: return 17
        default:      return 15
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TotalSpentCardView(totalAmount: "1,229.89 €", onAddExpense: {})
        TotalSpentCardView(totalAmount: "52,340.50 USD", onAddExpense: {})
    }
    .padding()
    .background(Color.black)
}
