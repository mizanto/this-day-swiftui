//
//  DataRepository.swift
//  this-day
//
//  Created by Sergey Bendak on 3.10.2024.
//

import Foundation
import Combine

enum RepositoryError: Error {
    case unauthorized
    case notFound
    case fetchError
    case saveError
    case deleteError
    case unknownError(String)
}

protocol DataRepositoryProtocol {
    func fetchDay(date: Date, language: String) -> AnyPublisher<DayDataModel, RepositoryError>
    func toggleBookmark(for eventID: String) -> AnyPublisher<Bool, RepositoryError>
    func fetchBookmarkedEvents() -> AnyPublisher<[EventDataModel], RepositoryError>
    func syncBookmarks() -> AnyPublisher<Void, RepositoryError>
    func clearLocalStorage() -> AnyPublisher<Void, RepositoryError>
}

final class DataRepository: DataRepositoryProtocol {
    private let localStorage: LocalStorageProtocol
    private let cloudStorage: CloudStorageProtocol
    private let networkService: NetworkServiceProtocol

    init(localStorage: LocalStorageProtocol,
         cloudStorage: CloudStorageProtocol,
         networkService: NetworkServiceProtocol) {
        self.localStorage = localStorage
        self.cloudStorage = cloudStorage
        self.networkService = networkService
    }

    func fetchDay(date: Date, language: String) -> AnyPublisher<DayDataModel, RepositoryError> {
        AppLogger.shared.debug(
            "[Repo]: Start fetching day for date \(date) and language \(language)", category: .repository)
        let id = DayEntity.createID(date: date, language: language)
        return localStorage.fetchDay(id: id)
            .mapError { error in
                AppLogger.shared.error("[Repo]: Failed to fetch day locally for id \(id) with error: \(error)",
                                       category: .repository)
                return RepositoryError.fetchError
            }
            .flatMap { [unowned self] dayEntity -> AnyPublisher<DayDataModel, RepositoryError> in
                if let dayEntity = dayEntity {
                    AppLogger.shared.debug("[Repo]: Found day entity for id \(id)", category: .repository)
                    return Just(DayDataModel(entity: dayEntity))
                        .setFailureType(to: RepositoryError.self)
                        .eraseToAnyPublisher()
                } else {
                    AppLogger.shared.debug(
                        "[Repo]: No day entity found for id \(id), fetching from network", category: .repository)
                    return self.networkService.fetchEvents(for: date, language: language)
                        .mapError { error in
                            AppLogger.shared.error("[Repo]: Failed to fetch events for \(date) with error: \(error)",
                                                   category: .repository)
                            return RepositoryError.fetchError
                        }
                        .flatMap { [weak self] dayModel -> AnyPublisher<DayEntity, RepositoryError> in
                            guard let self = self else {
                                return Fail(error: RepositoryError.unknownError("Self is nil"))
                                    .eraseToAnyPublisher()
                            }
                            AppLogger.shared.debug("[Repo]: Saving day model to local storage", category: .repository)
                            return self.saveDay(networkModel: dayModel, by: id, for: date, language: language)
                        }
                        .map { DayDataModel(entity: $0) }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func toggleBookmark(for eventID: String) -> AnyPublisher<Bool, RepositoryError> {
        AppLogger.shared.debug("[Repo]: Toggle bookmark for event \(eventID).", category: .ui)
        return localStorage.fetchEvent(id: eventID)
            .mapError { _ in RepositoryError.fetchError }
            .flatMap { [unowned self] event -> AnyPublisher<Bool, RepositoryError> in
                guard let event else {
                    AppLogger.shared.error("[Repo]: Failed to toggle bookmark for event \(eventID). Event not found.",
                                           category: .repository)
                    return Fail(error: RepositoryError.notFound).eraseToAnyPublisher()
                }
                if let bookmark = event.bookmark {
                    AppLogger.shared.debug("[Repo]: Remove bookmark for event \(eventID).", category: .repository)
                    return self.removeBookmark(bookmark)
                        .map { false }
                        .eraseToAnyPublisher()
                } else {
                    AppLogger.shared.debug("[Repo]: Add event \(eventID) to bookmarks.", category: .repository)
                    return self.addToBookmarks(event: event)
                        .map { true }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchBookmarks() -> AnyPublisher<[BookmarkEntity], RepositoryError> {
        AppLogger.shared.debug("[Repo]: Start fetching bookmarks", category: .repository)
        return localStorage.fetchBookmarks()
            .mapError { _ in RepositoryError.fetchError }
            .eraseToAnyPublisher()
    }

    func fetchBookmarkedEvents() -> AnyPublisher<[EventDataModel], RepositoryError> {
        AppLogger.shared.debug("[Repo]: Start fetching bookmarked events", category: .repository)
        return localStorage.fetchBookmarks()
            .mapError { _ in RepositoryError.saveError }
            .map { bookmarks in
                return bookmarks.compactMap { bookmark in
                    guard let event = bookmark.event else { return nil }
                    return EventDataModel(entity: event)
                }
            }
            .eraseToAnyPublisher()
    }

    func syncBookmarks() -> AnyPublisher<Void, RepositoryError> {
        return localStorage.fetchBookmarks()
            .mapError { error in
                AppLogger.shared.error(
                    "[Repo]: Failed to fetch bookmarks from local storage: \(error)", category: .repository)
                return RepositoryError.fetchError
            }
            .flatMap { localBookmarks in
                guard localBookmarks.isEmpty else {
                    AppLogger.shared.debug(
                        "[Repo]: Found \(localBookmarks.count) bookmarks in local storage", category: .repository)
                    return Just(()).setFailureType(to: RepositoryError.self).eraseToAnyPublisher()
                }
                return self.cloudStorage.fetchBookmarks()
                    .mapError { error in
                        AppLogger.shared.error(
                            "[Repo]: Failed to fetch bookmarks from cloud storage: \(error)", category: .repository)
                        return RepositoryError.fetchError
                    }
                    .flatMap { [unowned self] cloudBookmarks -> AnyPublisher<Void, RepositoryError> in
                        AppLogger.shared.debug(
                            "[Repo]: Found \(cloudBookmarks.count) bookmarks in cloud storage", category: .repository)
                        return self.tryToSaveCloudBookmarks(cloudBookmarks)
                    }
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

//    func syncBookmarks() -> AnyPublisher<Void, RepositoryError> {
//        AppLogger.shared.debug("[Repo]: Start syncing bookmarks", category: .repository)
//        return localStorage.fetchBookmarks()
//            .flatMap { localBookmarks in
//                AppLogger.shared.debug(
//                    "[Repo]: Found \(localBookmarks.count) bookmarks in local storage", category: .repository)
//                if localBookmarks.isEmpty {
//                    AppLogger.shared.debug(
//                        "[Repo]: No bookmarks in local storage, fetching from cloud", category: .repository)
//                    return self.cloudStorage.fetchBookmarks()
//                } else {
//                    return Just([])
//                        .setFailureType(to: StorageError.self)
//                        .eraseToAnyPublisher()
//                }
//            }
//            .mapError { error in
//                AppLogger.shared.error(
//                    "[Repo]: Failed to fetch bookmarks from cloud storage: \(error)", category: .repository)
//                return RepositoryError.fetchError
//            }
//            .flatMap { [weak self] cloudBookmarks -> AnyPublisher<Void, RepositoryError> in
//                AppLogger.shared.debug(
//                    "[Repo]: Found \(cloudBookmarks.count) bookmarks in cloud storage", category: .repository)
//                guard let self else {
//                    return Fail(error: RepositoryError.fetchError)
//                        .eraseToAnyPublisher()
//                }
//                return self.tryToSaveCloudBookmarks(cloudBookmarks)
//            }
//            .map { _ in () }
//            .eraseToAnyPublisher()
//    }

    func clearLocalStorage() -> AnyPublisher<Void, RepositoryError> {
        AppLogger.shared.debug("Clearing local storage", category: .repository)
        return localStorage.clearStorage()
            .mapError { error in
                AppLogger.shared.error("Failed to clear local storage: \(error)", category: .repository)
                return RepositoryError.deleteError
            }
            .eraseToAnyPublisher()
    }

    private func addToBookmarks(event: EventEntity) -> AnyPublisher<Void, RepositoryError> {
        let date = Date()
        let id = UUID().uuidString
        return Publishers.Zip(
            self.localStorage.addToBookmarks(event: event, by: id, dateAdded: date),
            self.cloudStorage.addBookmark(id: id, eventID: event.id, dateAdded: date)
        )
        .map { _ in () }
        .mapError { error in
            AppLogger.shared.error("Failed to add bookmark: \(error)", category: .repository)
            if case .saveError = error {
                return .unauthorized
            } else {
                return .saveError
            }
        }
        .eraseToAnyPublisher()
    }

    private func removeBookmark(_ bookmark: BookmarkEntity) -> AnyPublisher<Void, RepositoryError> {
        let id = bookmark.id
        return Publishers.Zip(
            self.localStorage.removeBookmark(id: id),
            self.cloudStorage.removeBookmark(id: id)
        )
        .map { _ in () }
        .mapError { error in
            AppLogger.shared.error("Failed to remove bookmark: \(error)", category: .repository)
            if case .saveError = error {
                return .unauthorized
            } else {
                return .deleteError
            }
        }
        .eraseToAnyPublisher()
    }

    private func tryToSaveCloudBookmarks(_ bookmarks: [BookmarkDataModel]) -> AnyPublisher<Void, RepositoryError> {
        guard !bookmarks.isEmpty else {
            AppLogger.shared.debug("[Repo]: No bookmarks to save", category: .repository)
            return Just(())
                .setFailureType(to: RepositoryError.self)
                .eraseToAnyPublisher()
        }

        AppLogger.shared.debug("[Repo]: Trying to save cloud bookmarks: \(bookmarks)", category: .repository)
        let eventIDs = bookmarks.map { $0.eventID }
        let dayIDs = eventIDs
            .compactMap { EventEntity.extractDayID(from: $0) }
            .removingDuplicates()

        return self.localStorage.fetchDays()
            .map { entities -> [String] in
                let localDayIDs = entities.map { $0.id }
                let missingIDs = dayIDs.filter { !localDayIDs.contains($0) }
                AppLogger.shared.debug("[Repo]: Missing days: \(missingIDs)", category: .repository)
                return missingIDs
            }
            .mapError { error in
                AppLogger.shared.error("[Repo]: Failed to fetch missing days: \(error)", category: .repository)
                return RepositoryError.fetchError
            }
            .flatMap { [unowned self] missingDayIDs -> AnyPublisher<[(String, DayNetworkModel)], RepositoryError> in
                AppLogger.shared.debug("[Repo]: Fetching missing days: \(missingDayIDs)", category: .repository)
                return self.fetchDays(ids: missingDayIDs)
            }
            .flatMap { [unowned self] fetchedDays -> AnyPublisher<Void, RepositoryError> in
                AppLogger.shared.debug("[Repo]: Saving fetched days", category: .repository)
                return self.saveDaysLocally(fetchedDays)
            }
            .flatMap { [unowned self] _ -> AnyPublisher<Void, Never> in
                AppLogger.shared.debug("[Repo]: Saving fetched bookmarks: \(bookmarks)", category: .repository)
                return self.saveBokmarksLocally(bookmarks)
            }
            .eraseToAnyPublisher()
    }

    private func fetchDays(ids: [String]) -> AnyPublisher<[(String, DayNetworkModel)], RepositoryError> {
        guard !ids.isEmpty else {
            return Just<[(String, DayNetworkModel)]>([])
                .setFailureType(to: RepositoryError.self)
                .eraseToAnyPublisher()
        }

        let fetchPublishers = ids.map { dayID in
            guard let (date, language) = DayEntity.extractDateAndLanguage(from: dayID) else {
                return Fail<(String, DayNetworkModel), RepositoryError>(error: .unknownError("Unknown dayID: \(dayID)"))
                    .eraseToAnyPublisher()
            }
            return self.networkService.fetchEvents(for: date, language: language)
                .map { (dayID, $0) }
                .mapError { _ in RepositoryError.fetchError }
                .eraseToAnyPublisher()
        }
        return Publishers.MergeMany(fetchPublishers)
            .collect()
            .eraseToAnyPublisher()
    }

    // swiftlint:disable:next line_length
    private func saveDaysLocally(_ days: [(id: String, model: DayNetworkModel)]) -> AnyPublisher<Void, RepositoryError> {
        guard !days.isEmpty else {
            return Just(())
                .setFailureType(to: RepositoryError.self)
                .eraseToAnyPublisher()
        }

        let savePublishers = days.map { dayID, dayModel in
            guard let (date, language) = DayEntity.extractDateAndLanguage(from: dayID) else {
                return Fail<Void, RepositoryError>(error: .fetchError)
                    .eraseToAnyPublisher()
            }
            return self.saveDay(networkModel: dayModel, by: dayID, for: date, language: language)
                .map { _ in () }
                .eraseToAnyPublisher()
        }
        return Publishers.MergeMany(savePublishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func saveBokmarksLocally(_ bookmarks: [BookmarkDataModel]) -> AnyPublisher<Void, Never> {
        let saveBookmarksPublishers = bookmarks.map { bookmark in
            return self.localStorage.addToBookmarksEvent(eventID: bookmark.eventID,
                                                         bookmarkID: bookmark.id,
                                                         dateAdded: bookmark.dateAdded)
            .catch { [unowned self] error in
                if case .notFound = error {
                    return self.cloudStorage.removeBookmark(id: bookmark.id)
                        .replaceError(with: ())
                        .eraseToAnyPublisher()
                } else {
                    return Just(()).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        }
        return Publishers.MergeMany(saveBookmarksPublishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func saveDay(networkModel: DayNetworkModel,
                         by id: String,
                         for date: Date,
                         language: String) -> AnyPublisher<DayEntity, RepositoryError> {
        localStorage.saveDay(networkModel: networkModel, id: id, date: date, language: language)
            .mapError { error in
                AppLogger.shared.error("[Repo]: Failed to fetch events for \(date) with error: \(error)", category: .repository)
                return RepositoryError.fetchError
            }
            .eraseToAnyPublisher()
    }
}
