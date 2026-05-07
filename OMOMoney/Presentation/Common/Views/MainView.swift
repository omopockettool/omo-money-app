//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import OSLog

struct MainView: View {
    @State private var viewModel: MainViewModel
    @State private var hasCheckedForUsers = false

    private static let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.MainView")

    init() {
        _viewModel = State(wrappedValue: MainViewModel())
        Self.logger.debug("init")
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
        .task {
            guard !hasCheckedForUsers else {
                Self.logger.debug("task skipped because initial user check already ran")
                return
            }

            hasCheckedForUsers = true
            Self.logger.debug("task starting initial user check")
            await viewModel.checkForUsers()
            Self.logger.debug("task finished initial user check hasUsers=\(viewModel.hasUsers)")
        }
    }
}

#Preview {
    MainView()
}
