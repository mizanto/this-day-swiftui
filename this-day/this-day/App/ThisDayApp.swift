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
    let localizationManager: LocalizationManager

    @StateObject var coordinator: FlowCoordinator

    init() {
        FirebaseApp.configure()

        let auth = AuthenticationService()
        self.authService = auth
        let context = PersistenceController.shared.container.viewContext
        let repository = DataRepository(
            localStorage: LocalStorage(context: context),
            cloudStorage: CloudStorage(authService: authService),
            networkService: NetworkService()
        )
        self.dataRepository = repository
        let localization = LocalizationManager()
        self.localizationManager = localization
        _coordinator = StateObject(
            wrappedValue: FlowCoordinator(
                dataRepository: repository,
                authService: auth,
                localizationManager: localization
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
