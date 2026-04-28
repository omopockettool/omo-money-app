//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel: MainViewModel

    init() {
        _viewModel = State(wrappedValue: MainViewModel())
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                SplashView()
            } else if viewModel.hasUsers {
                AppContentView()
            } else {
                CreateFirstUserView(
                    onUserCreated: {
                        await viewModel.checkForUsers()
                    }
                )
            }
        }
        .onAppear {
            Task { await viewModel.checkForUsers() }
        }
    }
}

#Preview {
    MainView()
}
