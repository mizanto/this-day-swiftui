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

    @StateObject var localizationManager = LocalizationManager()

    init() {
        storageService = StorageService(context: persistenceController.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(networkService: networkService, storageService: storageService)
                .environmentObject(localizationManager)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                    localizationManager.objectWillChange.send()
                }
        }
    }
}
