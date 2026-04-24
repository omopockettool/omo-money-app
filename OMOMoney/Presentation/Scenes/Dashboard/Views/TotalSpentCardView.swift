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
    let currentRawAmount: Double
    let onAddExpense: () -> Void
    var isSuccess: Bool = false
    var successLabel: String = ""

    @State private var displayedAmount: String = ""
    @State private var isDecreasing: Bool = false
    @State private var flashColor: Color = .clear
    @State private var cardScale: CGFloat = 1.0
    @State private var isAddPressed = false

    var body: some View {
        Button(action: isSuccess ? {} : onAddExpense) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if isSuccess {
                        Text(successLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .transition(.push(from: .top).combined(with: .opacity))

                        Text("¡Listo!")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .transition(.push(from: .top).combined(with: .opacity))

                        Label("añadida a tu lista", systemImage: "arrow.down")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    } else {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .animation(.easeInOut(duration: 0.2), value: label)
                            .transition(.push(from: .bottom).combined(with: .opacity))

                        Text(displayedAmount)
                            .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText(countsDown: isDecreasing))
                            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: displayedAmount)
                            .transition(.push(from: .bottom).combined(with: .opacity))


                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(AnimationHelper.smoothSpring, value: isSuccess)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(isSuccess ? Color.green.opacity(0.45) : Color.accentColor.opacity(0.45))
                        .frame(width: 48, height: 48)
                        .offset(y: 4)

                    Circle()
                        .fill(isSuccess ? Color.green : Color.accentColor)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: isSuccess ? "checkmark" : "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .contentTransition(.symbolEffect(.replace.downUp))
                        }
                        .offset(y: isAddPressed ? 4 : 0)
                }
                .frame(width: 48, height: 52)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSuccess)
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
                .onChanged { _ in if !isSuccess { isAddPressed = true } }
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
            guard !isSuccess else { return }
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
        TotalSpentCardView(
            label: "Coste de hoy", totalAmount: "50,45 €",
            currentRawAmount: 50.45,
            onAddExpense: {}
        )
        TotalSpentCardView(
            label: "Coste de hoy", totalAmount: "50,45 €",
            currentRawAmount: 50.45,
            onAddExpense: {},
            isSuccess: true, successLabel: "Compras del súper"
        )
    }
    .padding()
    .background(Color.black)
}
