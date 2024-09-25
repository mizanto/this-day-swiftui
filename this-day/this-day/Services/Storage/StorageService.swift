//
//  StorageService.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation
import CoreData

protocol StorageServiceProtocol {
    func fetchDay(for id: String) throws -> DayEntity?
    func saveDay(networkModel: DayNetworkModel, for date: Date) throws
    func fetchEvent(for id: UUID) throws -> EventEntity?
    func addToBookmarks(event: EventEntity) throws
    func removeFromBookmarks(event: EventEntity) throws
    func fetchBookmarks() throws -> [EventEntity]
}

class StorageService: StorageServiceProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchDay(for id: String) throws -> DayEntity? {
        let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let days = try context.fetch(request)
            return days.first
        } catch {
            AppLogger.shared.error("Error fetching DayEntity for id \(id): \(error)", category: .database)
            throw StorageServiceError.fetchError(error)
        }
    }

    func saveDay(networkModel: DayNetworkModel, for date: Date) throws {
        let idString = date.toFormat("MM_dd")

        if let existingDay = try fetchDay(for: idString) {
            context.delete(existingDay)
        }

        _ = DayEntity.from(networkModel: networkModel, date: date, context: context)
        do {
            try context.save()
            AppLogger.shared.info("Successfully saved DayEntity for id: \(idString)", category: .database)
        } catch {
            AppLogger.shared.error("Failed to save DayEntity for id \(idString): \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func fetchEvent(for id: UUID) throws -> EventEntity? {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let events = try context.fetch(request)
            return events.first  // Возвращаем nil, если не найдено
        } catch {
            AppLogger.shared.error("Error fetching EventEntity for id \(id): \(error)", category: .database)
            throw StorageServiceError.fetchError(error)
        }
    }

    func addToBookmarks(event: EventEntity) throws {
        do {
            event.inBookmarks = true
            try context.save()
            AppLogger.shared.info("Successfully added event \(event.id) to favorites", category: .database)
        } catch {
            AppLogger.shared.error("Failed to add event \(event.id) to favorites: \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func removeFromBookmarks(event: EventEntity) throws {
        do {
            event.inBookmarks = false
            try context.save()
            AppLogger.shared.info("Successfully removed event \(event.id) from favorites", category: .database)
        } catch {
            AppLogger.shared.error("Failed to remove event \(event.id) from favorites: \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func fetchBookmarks() throws -> [EventEntity] {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "inBookmarks == true")

        do {
            let favoriteEvents = try context.fetch(request)
            return favoriteEvents
        } catch {
            AppLogger.shared.error("Failed to fetch favorite events: \(error)", category: .database)
            throw StorageServiceError.fetchError(error)
        }
    }
}
