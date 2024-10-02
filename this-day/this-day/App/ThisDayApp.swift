//
//  ThisDayApp.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import FirebaseCore

@main
struct ThisDayApp: App {
    let persistenceController = PersistenceController.shared
    let storageService: StorageService
    let networkService: NetworkService
    let authService: AuthenticationService

    @StateObject var localizationManager = LocalizationManager()

    init() {
        FirebaseApp.configure()
        storageService = StorageService(context: persistenceController.container.viewContext)
        networkService = NetworkService()
        authService = AuthenticationService()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(networkService: networkService,
                        storageService: storageService,
                        authService: authService)
                .environmentObject(localizationManager)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                    localizationManager.objectWillChange.send()
                }
        }
    }
}
