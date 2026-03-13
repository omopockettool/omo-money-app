//
//  ContentView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

/// ✅ Clean Architecture: Entry point - no Core Data dependencies
struct ContentView: View {
    var body: some View {
        MainView()
            .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
