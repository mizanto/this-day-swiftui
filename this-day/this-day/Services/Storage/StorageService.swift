//
//  StorageService.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation
import CoreData

protocol StorageServiceProtocol {
    func fetchDay(id: String) throws -> DayEntity?
    func saveDay(networkModel: DayNetworkModel, for date: Date) throws
    func fetchEvent(id: UUID) throws -> EventEntity?
    func addToBookmarks(event: EventEntity) throws
    func removeFromBookmarks(event: EventEntity) throws
    func removeBookmark(id: UUID) throws
    func fetchBookmarks() throws -> [BookmarkEntity]
}

class StorageService: StorageServiceProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchDay(id: String) throws -> DayEntity? {
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
        let id = date.toFormat("MM_dd")

        if let existingDay = try fetchDay(id: id) {
            context.delete(existingDay)
        }

        _ = DayEntity.from(networkModel: networkModel, date: date, context: context)
        do {
            try context.save()
            AppLogger.shared.info("Successfully saved DayEntity for id: \(id)", category: .database)
        } catch {
            AppLogger.shared.error("Failed to save DayEntity for id \(id): \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func fetchEvent(id: UUID) throws -> EventEntity? {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let events = try context.fetch(request)
            return events.first
        } catch {
            AppLogger.shared.error("Error fetching EventEntity for id \(id): \(error)", category: .database)
            throw StorageServiceError.fetchError(error)
        }
    }

    func addToBookmarks(event: EventEntity) throws {
        let bookmark = BookmarkEntity(context: context)
        bookmark.id = UUID()
        bookmark.dateAdded = Date()
        bookmark.event = event

        do {
            try context.save()
            AppLogger.shared.info("Successfully added event \(event.id) to bookmarks", category: .database)
        } catch {
            AppLogger.shared.error("Failed to add event \(event.id) to bookmarks: \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func removeFromBookmarks(event: EventEntity) throws {
        let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        request.predicate = NSPredicate(format: "event == %@", event)

        do {
            let bookmarks = try context.fetch(request)
            if let bookmarkToDelete = bookmarks.first {
                context.delete(bookmarkToDelete)
                try context.save()
                AppLogger.shared.info("Successfully removed event \(event.id) from bookmarks",
                                      category: .database)
            } else {
                AppLogger.shared.warning("No bookmark found for event \(event.id) to remove",
                                         category: .database)
            }
        } catch {
            AppLogger.shared.error("Failed to remove event \(event.id) from bookmarks: \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func removeBookmark(id: UUID) throws {
        let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let bookmarkToDelete = try context.fetch(request).first {
                context.delete(bookmarkToDelete)
                try context.save()
                AppLogger.shared.info("Successfully removed event \(id) from bookmarks",
                                      category: .database)
            } else {
                AppLogger.shared.warning("No bookmark found for event \(id) to remove",
                                         category: .database)
            }
        } catch {
            AppLogger.shared.error("Failed to remove event \(id) from bookmarks: \(error)", category: .database)
            throw StorageServiceError.saveError(error)
        }
    }

    func fetchBookmarks() throws -> [BookmarkEntity] {
        let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]

        do {
            let bookmarks = try context.fetch(request)
            AppLogger.shared.info("Successfully fetched \(bookmarks.count) bookmarks",
                                  category: .database)
            return bookmarks
        } catch {
            AppLogger.shared.error("Failed to fetch bookmarks: \(error)", category: .database)
            throw StorageServiceError.fetchError(error)
        }
    }
}
