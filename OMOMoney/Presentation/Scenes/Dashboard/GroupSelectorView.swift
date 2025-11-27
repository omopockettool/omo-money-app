//
//  GroupSelectorView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI

/// Selector de grupo ubicado en la parte inferior del dashboard
/// Implementa NEAR UX - acceso fácil con el pulgar
struct GroupSelectorView: View {
    let currentGroup: Group
    let availableGroups: [Group]
    let onGroupChange: (Group) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Lista de grupos disponibles
                VStack(spacing: 0) {
                    ForEach(availableGroups, id: \.objectID) { group in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                onGroupChange(group)
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(group.name ?? "Sin nombre")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if group.objectID == currentGroup.objectID {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, AppConstants.UserInterface.padding)
                            .padding(.vertical, 12)
                            .background(
                                group.objectID == currentGroup.objectID
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if group.objectID != availableGroups.last?.objectID {
                            Divider()
                                .padding(.leading, AppConstants.UserInterface.padding)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Selector principal (siempre visible)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grupo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currentGroup.name ?? "Sin nombre")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(isExpanded ? 0 : 12, corners: isExpanded ? [.bottomLeft, .bottomRight] : .allCorners)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Helper Extension for Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        GroupSelectorView(
            currentGroup: Group(),
            availableGroups: [Group(), Group()],
            onGroupChange: { _ in }
        )
    }
    .background(Color.black)
}
