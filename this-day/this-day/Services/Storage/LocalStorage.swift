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
    func fetchDay(id: String) -> AnyPublisher<DayEntity?, StorageError>
    func fetchDays() -> AnyPublisher<[DayEntity], StorageError>
    func saveDay(networkModel: DayNetworkModel, id: String,
                 date: Date, language: String) -> AnyPublisher<DayEntity, StorageError>
    func fetchEvent(id: String) -> AnyPublisher<EventEntity?, StorageError>
    func addToBookmarks(event: EventEntity, by id: String, dateAdded: Date) -> AnyPublisher<Void, StorageError>
    func addToBookmarksEvent(eventID: String, bookmarkID: String, dateAdded: Date) -> AnyPublisher<Void, StorageError>
    func removeBookmark(id: String) -> AnyPublisher<Void, StorageError>
    func fetchBookmarks() -> AnyPublisher<[BookmarkEntity], StorageError>
    func clearStorage() -> AnyPublisher<Void, StorageError>
}

class LocalStorage: LocalStorageProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
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
                AppLogger.shared.error(
                    "[Local Storage]: Error fetching DayEntity for id \(id): \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchDays() -> AnyPublisher<[DayEntity], StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }

            let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
            do {
                let days = try self.context.fetch(request)
                promise(.success(days))
            } catch {
                AppLogger.shared.error("[Local Storage]: Error fetching Days: \(error)", category: .database)
                promise(.failure(.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func saveDay(networkModel: DayNetworkModel, id: String,
                 date: Date, language: String) -> AnyPublisher<DayEntity, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }

            do {
                if let day = try self.fetchDaySync(id: id) {
                    promise(.success(day))
                    return
                }

                let day = DayEntity.from(model: networkModel, id: id, date: date,
                                         language: language, context: self.context)
                try self.context.obtainPermanentIDs(for: [day])
                try self.context.save()
                AppLogger.shared.info(
                    "[Local Storage]: Successfully saved DayEntity for id: \(id):", category: .database)
                promise(.success(day))
            } catch {
                AppLogger.shared.error(
                    "[Local Storage]: Failed to save DayEntity for id \(id): \(error)", category: .database)
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
                AppLogger.shared.debug("[Local Storage]: Fetching EventEntity for id \(id):", category: .database)
                let events = try self.context.fetch(request)
                promise(.success(events.first))
            } catch {
                AppLogger.shared.error(
                    "[Local Storage]: Error fetching EventEntity for id \(id): \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func addToBookmarks(event: EventEntity, by id: String, dateAdded: Date) -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }

            let bookmark = BookmarkEntity(context: self.context)
            bookmark.id = id
            bookmark.dateAdded = dateAdded
            bookmark.event = event

            do {
                try self.context.save()
                AppLogger.shared.info(
                    "[Local Storage]: Successfully added event \(event.id) to bookmarks", category: .database)
                promise(.success(()))
            } catch {
                AppLogger.shared.error(
                    "[Local Storage]: Failed to add event \(event.id) to bookmarks: \(error)", category: .database)
                promise(.failure(StorageError.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func addToBookmarksEvent(eventID: String, bookmarkID: String, dateAdded: Date) -> AnyPublisher<Void, StorageError> {
        return fetchEvent(id: eventID)
            .flatMap { [weak self] event -> AnyPublisher<Void, StorageError> in
                guard let self else {
                    return Fail(error: .unknownError("Self is nil")).eraseToAnyPublisher()
                }

                if let event {
                    return self.addToBookmarks(event: event, by: bookmarkID, dateAdded: dateAdded)
                } else {
                    return Fail(error: .notFound).eraseToAnyPublisher()
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
                    AppLogger.shared.info(
                        "[Local Storage]: Successfully removed event \(event.id) from bookmarks", category: .database)
                    promise(.success(()))
                } else {
                    AppLogger.shared.warning(
                        "[Local Storage]: No bookmark found for event \(event.id) to remove", category: .database)
                    promise(.success(()))
                }
            } catch {
                AppLogger.shared.error("[Local Storage]: Failed to remove event \(event.id) from bookmarks: \(error)",
                                       category: .database)
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
                    AppLogger.shared.info(
                        "[Local Storage]: Successfully removed bookmark with id \(id)", category: .database)
                    promise(.success(()))
                } else {
                    AppLogger.shared.warning(
                        "[Local Storage]: No bookmark found with id \(id) to remove", category: .database)
                    promise(.success(()))
                }
            } catch {
                AppLogger.shared.error(
                    "[Local Storage]: Failed to remove bookmark with id \(id): \(error)", category: .database)
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
                AppLogger.shared.info(
                    "[Local Storage]: Successfully fetched \(bookmarks.count) bookmarks", category: .database)
                promise(.success(bookmarks))
            } catch {
                AppLogger.shared.error("[Local Storage]: Failed to fetch bookmarks: \(error)", category: .database)
                promise(.failure(StorageError.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func clearStorage() -> AnyPublisher<Void, StorageError> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("Self is nil")))
                return
            }

            guard let persistentStoreCoordinator = self.context.persistentStoreCoordinator else {
                promise(.failure(.unknownError("Persistent Store Coordinator is nil")))
                return
            }

            let entities = persistentStoreCoordinator.managedObjectModel.entities

            do {
                for entity in entities {
                    guard let entityName = entity.name else { continue }
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDeleteRequest.resultType = .resultTypeObjectIDs

                    let result = try self.context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                        let changes = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                    }
                }

                AppLogger.shared.info("[Local Storage]: Successfully cleared storage", category: .database)
                promise(.success(()))
            } catch {
                AppLogger.shared.error("[Local Storage]: Failed to clear storage: \(error)", category: .database)
                promise(.failure(.deleteError(error)))
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
