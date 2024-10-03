//
//  LocalStorage.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation
import CoreData
import Combine

protocol LocalStorageProtocol {
    func fetchDay(id: String) throws -> DayEntity?
    func saveDay(networkModel: DayNetworkModel, for date: Date, language: String) throws
    func fetchEvent(id: String) throws -> EventEntity?
    func addToBookmarks(event: EventEntity) throws
    func removeFromBookmarks(event: EventEntity) throws
    func removeBookmark(id: String) throws
    func fetchBookmarks() throws -> [BookmarkEntity]
    
    func fetchDay(id: String) -> AnyPublisher<DayEntity?, StorageError>
    func saveDay(networkModel: DayNetworkModel,
                 for date: Date,
                 language: String) -> AnyPublisher<Void, StorageError>
    func fetchEvent(id: String) -> AnyPublisher<EventEntity?, StorageError>
    func addToBookmarks(event: EventEntity) -> AnyPublisher<Void, StorageError>
    func removeFromBookmarks(event: EventEntity) -> AnyPublisher<Void, StorageError>
    func removeBookmark(id: String) -> AnyPublisher<Void, StorageError>
    func fetchBookmarks() -> AnyPublisher<[BookmarkEntity], StorageError>
}

class LocalStorage: LocalStorageProtocol {

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
            throw StorageError.fetchError(error)
        }
    }

    func saveDay(networkModel: DayNetworkModel, for date: Date, language: String) throws {
        let id = DayEntity.createID(date: date, language: language)

        if let existingDay = try fetchDay(id: id) {
            context.delete(existingDay)
        }

        _ = DayEntity.from(networkModel: networkModel,
                           date: date,
                           language: language,
                           context: context)
        do {
            try context.save()
            AppLogger.shared.info("Successfully saved DayEntity for id: \(id)", category: .database)
        } catch {
            AppLogger.shared.error("Failed to save DayEntity for id \(id): \(error)", category: .database)
            throw StorageError.saveError(error)
        }
    }

    func fetchEvent(id: String) throws -> EventEntity? {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let events = try context.fetch(request)
            return events.first
        } catch {
            AppLogger.shared.error("Error fetching EventEntity for id \(id): \(error)", category: .database)
            throw StorageError.fetchError(error)
        }
    }

    func addToBookmarks(event: EventEntity) throws {
        let bookmark = BookmarkEntity(context: context)
        bookmark.id = UUID().uuidString
        bookmark.dateAdded = Date()
        bookmark.event = event

        do {
            try context.save()
            AppLogger.shared.info("Successfully added event \(event.id) to bookmarks", category: .database)
        } catch {
            AppLogger.shared.error("Failed to add event \(event.id) to bookmarks: \(error)", category: .database)
            throw StorageError.saveError(error)
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
            throw StorageError.saveError(error)
        }
    }

    func removeBookmark(id: String) throws {
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
            throw StorageError.saveError(error)
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
            throw StorageError.fetchError(error)
        }
    }
    
    func fetchDay(id: String) -> AnyPublisher<DayEntity?, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let days = try self.context.fetch(request)
                promise(.success(days.first))
            } catch {
                AppLogger.shared.error("Error fetching DayEntity for id \(id): \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveDay(networkModel: DayNetworkModel, for date: Date, language: String) -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let id = DayEntity.createID(date: date, language: language)
            
            do {
                if let existingDay = try self.fetchDaySync(id: id) {
                    self.context.delete(existingDay)
                }
                
                _ = DayEntity.from(networkModel: networkModel,
                                   date: date,
                                   language: language,
                                   context: self.context)
                try self.context.save()
                AppLogger.shared.info("Successfully saved DayEntity for id: \(id)", category: .database)
                promise(.success(()))
            } catch {
                AppLogger.shared.error("Failed to save DayEntity for id \(id): \(error)", category: .database)
                promise(.failure(StorageError.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchEvent(id: String) -> AnyPublisher<EventEntity?, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let events = try self.context.fetch(request)
                promise(.success(events.first))
            } catch {
                AppLogger.shared.error("Error fetching EventEntity for id \(id): \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addToBookmarks(event: EventEntity) -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let bookmark = BookmarkEntity(context: self.context)
            bookmark.id = UUID().uuidString
            bookmark.dateAdded = Date()
            bookmark.event = event
            
            do {
                try self.context.save()
                AppLogger.shared.info("Successfully added event \(event.id) to bookmarks", category: .database)
                promise(.success(()))
            } catch {
                AppLogger.shared.error("Failed to add event \(event.id) to bookmarks: \(error)", category: .database)
                promise(.failure(StorageError.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeFromBookmarks(event: EventEntity) -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            request.predicate = NSPredicate(format: "event == %@", event)
            
            do {
                let bookmarks = try self.context.fetch(request)
                if let bookmarkToDelete = bookmarks.first {
                    self.context.delete(bookmarkToDelete)
                    try self.context.save()
                    AppLogger.shared.info("Successfully removed event \(event.id) from bookmarks", category: .database)
                    promise(.success(()))
                } else {
                    AppLogger.shared.warning("No bookmark found for event \(event.id) to remove", category: .database)
                    promise(.success(())) // Не считать ошибкой
                }
            } catch {
                AppLogger.shared.error("Failed to remove event \(event.id) from bookmarks: \(error)", category: .database)
                promise(.failure(StorageError.deleteError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeBookmark(id: String) -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                if let bookmarkToDelete = try self.context.fetch(request).first {
                    self.context.delete(bookmarkToDelete)
                    try self.context.save()
                    AppLogger.shared.info("Successfully removed bookmark with id \(id)", category: .database)
                    promise(.success(()))
                } else {
                    AppLogger.shared.warning("No bookmark found with id \(id) to remove", category: .database)
                    promise(.success(())) // Не считать ошибкой
                }
            } catch {
                AppLogger.shared.error("Failed to remove bookmark with id \(id): \(error)", category: .database)
                promise(.failure(StorageError.deleteError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchBookmarks() -> AnyPublisher<[BookmarkEntity], StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }
            
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
            
            do {
                let bookmarks = try self.context.fetch(request)
                AppLogger.shared.info("Successfully fetched \(bookmarks.count) bookmarks", category: .database)
                promise(.success(bookmarks))
            } catch {
                AppLogger.shared.error("Failed to fetch bookmarks: \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func fetchDaySync(id: String) throws -> DayEntity? {
        let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let days = try context.fetch(request)
        return days.first
    }
}
