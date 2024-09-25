//
//  ThisDayApp.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

@main
struct ThisDayApp: App {
    let persistenceController = PersistenceController.shared
    let storageService: StorageService
    let networkService = NetworkService()

    init() {
        storageService = StorageService(context: persistenceController.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(networkService: networkService, storageService: storageService)
        }
    }
}
