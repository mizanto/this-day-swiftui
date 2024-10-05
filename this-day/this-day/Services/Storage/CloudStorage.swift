//
//  CloudStorage.swift
//  this-day
//
//  Created by Sergey Bendak on 3.10.2024.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

protocol CloudStorageProtocol {
    func addBookmark(eventID: String) -> AnyPublisher<Void, StorageError>
    func removeBookmark(eventID: String) -> AnyPublisher<Void, StorageError>
    func fetchBookmarks() -> AnyPublisher<[BookmarkDataModel], StorageError>
}

final class CloudStorage: CloudStorageProtocol {
    let authService: AuthenticationServiceProtocol

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
    }

    func addBookmark(eventID: String) -> AnyPublisher<Void, StorageError> {
        guard let userID = authService.currentUser?.id else {
            AppLogger.shared.error("User is not logged in")
            return Fail(error: StorageError.unauthorized).eraseToAnyPublisher()
        }

        let bookmark = BookmarkDataModel(eventID: eventID, dateAdded: Date())
        return bookmarksReference(userID: userID)
            .addDocument(from: bookmark)
            .retry(3)
            .map { _ in () }
            .mapError { error in
                AppLogger.shared.error("Failed to add bookmark: \(error)")
                return StorageError.saveError(error)
            }
            .eraseToAnyPublisher()
    }

    func removeBookmark(eventID: String) -> AnyPublisher<Void, StorageError> {
        guard let userID = authService.currentUser?.id else {
            AppLogger.shared.error("User is not logged in")
            return Fail(error: StorageError.unauthorized).eraseToAnyPublisher()
        }

        let bookmarksRef = bookmarksReference(userID: userID)
        return bookmarksRef
            .whereField("eventID", isEqualTo: eventID)
            .getDocuments()
            .retry(3)
            .mapError { error in
                AppLogger.shared.error("Failed to fetch bookmarks: \(error)")
                return StorageError.fetchError(error)
            }
            .flatMap { snapshot -> AnyPublisher<Void, StorageError> in
                guard let document = snapshot.documents.first else {
                    return Just(())
                        .setFailureType(to: StorageError.self)
                        .eraseToAnyPublisher()
                }
                return bookmarksRef.document(document.documentID)
                    .delete()
                    .map { _ in () }
                    .mapError { error in
                        AppLogger.shared.error("Failed to delete bookmark: \(error)")
                        return StorageError.deleteError(error)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func fetchBookmarks() -> AnyPublisher<[BookmarkDataModel], StorageError> {
        guard let userID = authService.currentUser?.id else {
            AppLogger.shared.error("User is not logged in")
            return Fail(error: StorageError.unauthorized).eraseToAnyPublisher()
        }

        return bookmarksReference(userID: userID)
            .order(by: "dateAdded", descending: true)
            .getDocuments()
            .retry(3)
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: BookmarkDataModel.self) }
            }
            .mapError { error in
                AppLogger.shared.error("Error fetching bookmarks: \(error)")
                return StorageError.fetchError(error)
            }
            .eraseToAnyPublisher()
    }

    private func bookmarksReference(userID: String) -> CollectionReference {
        return Firestore.firestore().collection("users").document(userID).collection("bookmarks")
    }
}
