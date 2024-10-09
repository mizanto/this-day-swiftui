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

    @StateObject var coordinator: FlowCoordinator

    init() {
        FirebaseApp.configure()

        let auth = AuthenticationService()
        let context = PersistenceController.shared.container.viewContext
        _coordinator = StateObject(
            wrappedValue: FlowCoordinator(
                dataRepository: DataRepository(
                    localStorage: LocalStorage(context: context),
                    cloudStorage: CloudStorage(authService: auth),
                    networkService: NetworkService()
                ),
                authService: auth,
                localizationManager: LocalizationManager(),
                analyticsService: AnalyticsService.shared
            )
        )

        Apperance.apply()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                coordinator.view
            }
            .onAppear {
                coordinator.start()
            }
        }
    }
}
