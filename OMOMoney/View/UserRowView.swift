//
//  UserRowView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct UserRowView: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // User Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? "Unnamed User")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(user.email ?? "No Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let userGroups = user.userGroups, userGroups.count > 0 {
                            Label("\(userGroups.count) groups", systemImage: "person.3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Check if user is owner in any group
                        if let userGroups = user.userGroups {
                            let hasOwnerRole = userGroups.compactMap { $0 as? UserGroup }.contains { userGroup in
                                guard let role = userGroup.role else { return false }
                                return role == "owner"
                            }
                            if hasOwnerRole {
                                Label("Owner", systemImage: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    // Create a simple user for preview
    let user = User(context: context)
    user.id = UUID()
    user.name = "John Doe"
    user.email = "john@example.com"
    user.createdAt = Date()
    user.lastModifiedAt = Date()
    
    return UserRowView(user: user, onTap: {})
}
