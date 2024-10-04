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
    let authService: AuthenticationService
    let dataRepository: DataRepository

    @StateObject var localizationManager = LocalizationManager()

    init() {
        FirebaseApp.configure()
        authService = AuthenticationService()
        let context = PersistenceController.shared.container.viewContext
        dataRepository = DataRepository(
            localStorage: LocalStorage(context: context),
            cloudStorage: CloudStorage(authService: authService),
            networkService: NetworkService()
        )
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(authService: authService,
                        dataRepository: dataRepository)
                .environmentObject(localizationManager)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                    localizationManager.objectWillChange.send()
                }
        }
    }
}
