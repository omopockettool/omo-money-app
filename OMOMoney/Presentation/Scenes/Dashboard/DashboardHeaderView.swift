//
//  DashboardHeaderView.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct DashboardHeaderView: View {
    let onSettingsTap: () -> Void
    let onDebugTap: (() -> Void)?
    
    @State private var debugTapCount = 0
    
    init(onSettingsTap: @escaping () -> Void, onDebugTap: (() -> Void)? = nil) {
        self.onSettingsTap = onSettingsTap
        self.onDebugTap = onDebugTap
    }
    
    var body: some View {
        HStack {
            // App title with tap gesture for debug access
            Text("OMO")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .onTapGesture {
                    handleDebugAccess()
                }
            Text("Ni")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .onTapGesture {
                    handleDebugAccess()
                }
            
            Spacer()
            
            // Settings button (debug/test data)
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
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