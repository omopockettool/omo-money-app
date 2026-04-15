//
//  OMOMoneyApp.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import SwiftData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct OMOMoneyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let persistenceController = PersistenceController.shared
    let modelContainer = ModelContainer.shared
    
    // MARK: - Data Preloader
    @StateObject private var dataPreloader = {
        let context = PersistenceController.shared.container.viewContext
        let userService = UserService(context: context)
        let groupService = GroupService(context: context)
        let categoryService = CategoryService(context: context)
        let paymentMethodService = PaymentMethodService(context: context)
        
        return DataPreloader(
            userService: userService,
            groupService: groupService,
            categoryService: categoryService,
            paymentMethodService: paymentMethodService
        )
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(dataPreloader)
                .modelContainer(modelContainer)
                .task {
                    // Preload critical data on app launch for better performance
                    await dataPreloader.preloadCriticalData()
                }
        }
    }
}
