//
//  DataRepository.swift
//  this-day
//
//  Created by Sergey Bendak on 3.10.2024.
//

import Foundation
import Combine

enum RepositoryError: Error {
    case fetchError
    case saveError
    case unknownError(String)
}

protocol DataRepositoryProtocol {
    func fetchDay(date: Date, language: String) -> AnyPublisher<DayDataModel, RepositoryError>
    func toggleBookmark(for eventID: String) -> AnyPublisher<Void, RepositoryError>
    func fetchBookmarkedEvents() -> AnyPublisher<[EventDataModel], RepositoryError>
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
        let id = DayEntity.createID(date: date, language: language)
        return localStorage.fetchDay(id: id)
            .catch { _ in Just(nil) }
            .flatMap { [weak self] dayEntity -> AnyPublisher<DayDataModel, RepositoryError> in
                guard let self else {
                    return Fail(error: RepositoryError.unknownError("Self is nil"))
                        .eraseToAnyPublisher()
                }

                if let dayEntity {
                    return Just(DayDataModel(entity: dayEntity))
                        .setFailureType(to: RepositoryError.self)
                        .eraseToAnyPublisher()
                } else {
                    return self.networkService.fetchEvents(for: date, language: language)
                        .mapError { error in
                            AppLogger.shared.error("Failed to fetch events for \(date) with error: \(error)",
                                                   category: .repository)
                            return RepositoryError.fetchError
                        }
                        .flatMap { [weak self] dayModel -> AnyPublisher<DayEntity, RepositoryError> in
                            guard let self else {
                                return Fail(error: RepositoryError.unknownError("Self is nil"))
                                    .eraseToAnyPublisher()
                            }
                            return self.saveDay(networkModel: dayModel, by: id, for: date, language: language)
                        }
                        .map { DayDataModel(entity: $0) }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func toggleBookmark(for eventID: String) -> AnyPublisher<Void, RepositoryError> {
        localStorage.fetchEvent(id: eventID)
            .mapError { _ in RepositoryError.fetchError }
            .flatMap { [weak self] event -> AnyPublisher<Void, RepositoryError> in
                guard let self else {
                    return Fail(error: RepositoryError.unknownError("Self is nil")).eraseToAnyPublisher()
                }
                guard let event else {
                    AppLogger.shared.error("Failed to toggle bookmark for event \(eventID). Event not found.",
                                           category: .ui)
                    return Fail(error: RepositoryError.fetchError).eraseToAnyPublisher()
                }
                if event.inBookmarks {
                    return self.localStorage.removeFromBookmarks(event: event)
                        .mapError { _ in RepositoryError.saveError }
                        .eraseToAnyPublisher()
                } else {
                    return self.localStorage.addToBookmarks(event: event)
                        .mapError { _ in RepositoryError.saveError }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchBookmarks() -> AnyPublisher<[BookmarkEntity], RepositoryError> {
        localStorage.fetchBookmarks()
            .mapError { _ in RepositoryError.saveError }
            .eraseToAnyPublisher()
    }
    
    func fetchBookmarkedEvents() -> AnyPublisher<[EventDataModel], RepositoryError> {
        localStorage.fetchBookmarks()
            .mapError { _ in RepositoryError.saveError }
            .map { bookmarks in
                return bookmarks.compactMap { bookmark in
                    guard let event = bookmark.event else { return nil }
                    return EventDataModel(entity: event)
                }
            }
            .eraseToAnyPublisher()
    }

    private func saveDay(networkModel: DayNetworkModel,
                         by id: String,
                         for date: Date,
                         language: String) -> AnyPublisher<DayEntity, RepositoryError> {
        localStorage.saveDay(networkModel: networkModel, id: id, date: date, language: language)
            .mapError { error in
                AppLogger.shared.error("Failed to fetch events for \(date) with error: \(error)", category: .repository)
                return RepositoryError.fetchError
            }
            .eraseToAnyPublisher()
    }
}
