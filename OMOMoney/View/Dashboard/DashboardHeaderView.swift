//
//  DashboardHeaderView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct DashboardHeaderView: View {
    let groupName: String
    let onSettingsTap: () -> Void
    let onDebugTap: (() -> Void)?
    
    @State private var debugTapCount = 0
    
    init(groupName: String, onSettingsTap: @escaping () -> Void, onDebugTap: (() -> Void)? = nil) {
        self.groupName = groupName
        self.onSettingsTap = onSettingsTap
        self.onDebugTap = onDebugTap
    }
    
    var body: some View {
        HStack {
            // Group name with tap gesture for debug access
            Text(groupName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .onTapGesture {
                    handleDebugAccess()
                }
            
            Spacer()
            
            // Settings button
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }
    
    // MARK: - Private Methods
    
    /// Handle debug access through multiple taps on group name
    private func handleDebugAccess() {
        guard let debugTap = onDebugTap else { return }
        
        debugTapCount += 1
        
        // Reset counter after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            debugTapCount = 0
        }
        
        // Trigger debug after 5 taps
        if debugTapCount >= 5 {
            debugTapCount = 0
            debugTap()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        DashboardHeaderView(
            groupName: "Compras Ahorramas",
            onSettingsTap: {
                print("Settings tapped")
            },
            onDebugTap: {
                print("Debug activated!")
            }
        )
        
        Spacer()
    }
    .background(Color.black)
}