//
//  TotalSpentCardView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct TotalSpentCardView: View {
    let label: String
    let totalAmount: String
    var secondaryAmount: String? = nil
    var secondaryLabel: String? = nil
    let onAddExpense: () -> Void

    @State private var displayedAmount: String = ""
    @State private var isDecreasing: Bool = false
    @State private var flashColor: Color = .clear
    @State private var cardScale: CGFloat = 1.0
    @State private var isAddPressed = false

    var body: some View {
        Button(action: onAddExpense) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .animation(.easeInOut(duration: 0.2), value: label)

                    Text(displayedAmount)
                        .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText(countsDown: isDecreasing))
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: displayedAmount)

                    if let secondary = secondaryAmount {
                        HStack(spacing: 4) {
                            Text(secondary)
                            if let secLabel = secondaryLabel {
                                Text("· \(secLabel)")
                            }
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                ZStack {
                    // Base layer — the "depth" of the button
                    Circle()
                        .fill(Color.accentColor.opacity(0.45))
                        .frame(width: 48, height: 48)
                        .offset(y: 4)

                    // Top face — moves down to meet base on press
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(y: isAddPressed ? 4 : 0)
                }
                .frame(width: 48, height: 52)
                .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isAddPressed)
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 16)
            .background(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                    .fill(flashColor)
                    .allowsHitTesting(false)
            )
            .cornerRadius(AppConstants.UserInterface.cornerRadius)
            .scaleEffect(cardScale)
        }
        .buttonStyle(PressHapticButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isAddPressed = true }
                .onEnded   { _ in isAddPressed = false }
        )
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
        case 0...10:  return 34
        case 11...15: return 28
        case 16...20: return 22
        default:      return 18
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TotalSpentCardView(label: "Coste de vida este mes", totalAmount: "1,229.89 €", onAddExpense: {})
        TotalSpentCardView(label: "Coste de hoy", totalAmount: "52,340.50 USD", onAddExpense: {})
    }
    .padding()
    .background(Color.black)
}
