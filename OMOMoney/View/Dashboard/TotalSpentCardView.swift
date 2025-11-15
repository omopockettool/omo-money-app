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
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Fuente dinámica que se ajusta al tamaño del contenido
                Text(totalAmount)
                    .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5) // Se reduce hasta 50% si no cabe
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            // Botón más compacto
            Button(action: onAddExpense) {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
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
    
    // Calcula el tamaño de fuente basado en la longitud del texto
    private var dynamicFontSize: CGFloat {
        let length = totalAmount.count
        
        switch length {
        case 0...10:
            return 34 // Cantidades pequeñas: tamaño grande
        case 11...15:
            return 28 // Cantidades medianas
        case 16...20:
            return 24 // Cantidades grandes (100k - 999k)
        default:
            return 20 // Cantidades muy grandes (1M+)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Cantidad pequeña
        TotalSpentCardView(
            totalAmount: "1,229.89 €",
            onAddExpense: {}
        )
        
        // Cantidad mediana (5 dígitos)
        TotalSpentCardView(
            totalAmount: "52,340.50 USD",
            onAddExpense: {}
        )
        
        // Cantidad grande (6 dígitos)
        TotalSpentCardView(
            totalAmount: "850,299.99 $",
            onAddExpense: {}
        )
        
        // Cantidad muy grande (1M+)
        TotalSpentCardView(
            totalAmount: "1,234,567.89 USD",
            onAddExpense: {}
        )
    }
    .padding()
    .background(Color.black)
}