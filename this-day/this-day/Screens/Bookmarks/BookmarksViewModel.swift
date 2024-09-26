//
//  BookmarksViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import Combine
import Foundation

protocol BookmarksViewModelProtocol: ObservableObject {
    var state: ViewState<[BookmarkEvent]> { get }

    func onAppear()
    func removeBookmark(for eventID: UUID)
    func copyToClipboardEvent(id: UUID)
    func shareEvent(id: UUID)
}

final class BookmarksViewModel: BookmarksViewModelProtocol {
    @Published var state: ViewState<[BookmarkEvent]> = .data([])

    private let storageService: StorageServiceProtocol

    private var bookmarks: [BookmarkEntity] = [] {
        didSet {
            cacheBookmarks(bookmarks)
        }
    }
    private var uiModels: [BookmarkEvent] = []

    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }

    func onAppear() {
        AppLogger.shared.debug("BookmarksViewModel: onAppear", category: .ui)
        state = .loading

        do {
            bookmarks = try storageService.fetchBookmarks()
            state = .data(uiModels)
            AppLogger.shared.debug("Fetched \(bookmarks.count) bookmarks", category: .ui)
        } catch {
            AppLogger.shared.error("Failed to fetch bookmarks: \(error)", category: .ui)
            state = .error("Failed to fetch bookmarks")
        }
    }

    func removeBookmark(for id: UUID) {
        do {
            try storageService.removeBookmark(id: id)
            bookmarks = try storageService.fetchBookmarks()
            state = .data(uiModels)
        } catch {
            AppLogger.shared.error("Failed to remove bookmark: \(error)", category: .ui)
        }
    }

    func copyToClipboardEvent(id: UUID) {
        // TODO: Need to implement
    }

    func shareEvent(id: UUID) {
        // TODO: Need to implement
    }

    private func cacheBookmarks(_ bookmarks: [BookmarkEntity]) {
        uiModels = bookmarks.compactMap { bookmark in
            guard let event = bookmark.event else { return nil }

            return BookmarkEvent(
                id: bookmark.id,
                date: event.stringDate ?? "??????",
                title: event.title,
                subtitle: event.subtitle,
                inBookmarks: true,
                category: EventCategory.from(event.eventType)
            )
        }
    }
}
