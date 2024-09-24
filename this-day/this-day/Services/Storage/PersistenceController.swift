//
//  PersistenceController.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        AppLogger.shared.info("Initializing PersistenceController", category: .database)

        container = NSPersistentContainer(name: "Model")

        if inMemory {
            AppLogger.shared.info("Configuring in-memory store for PersistenceController", category: .database)
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                AppLogger.shared.error("Failed to load persistent stores: \(error), \(error.userInfo)", category: .database)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                AppLogger.shared.info("Successfully loaded persistent store at \(storeDescription.url?.absoluteString ?? "Unknown URL")", category: .database)
            }
        }
    }
}
