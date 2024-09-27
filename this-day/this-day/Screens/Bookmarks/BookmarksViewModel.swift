//
//  BookmarksViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import Combine
import Foundation
import UIKit

protocol BookmarksViewModelProtocol: ObservableObject {
    var state: ViewState<[BookmarkEvent]> { get }
    var itemsForSahre: ShareableItems? { get set }

    func onAppear()
    func removeBookmark(for eventID: UUID)
    func copyToClipboardBookmark(id: UUID)
    func shareBookmark(id: UUID)
}

final class BookmarksViewModel: BookmarksViewModelProtocol {
    @Published var state: ViewState<[BookmarkEvent]> = .initial
    @Published var itemsForSahre: ShareableItems?

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

    func copyToClipboardBookmark(id: UUID) {
        guard let stringToCopy = bookmarks.first(where: { $0.id == id })?.event?.toSharingString() else {
            AppLogger.shared.error("Failed to copy event \(id) to clipboard. No sharing string available.",
                                   category: .ui)
            return
        }
        UIPasteboard.general.string = stringToCopy
        AppLogger.shared.info("Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareBookmark(id: UUID) {
        guard let stringToShare = bookmarks.first(where: { $0.id == id })?.event?.toSharingString() else {
            AppLogger.shared.error("Failed to share event \(id) to social media. No sharing string available.",
                                   category: .ui)
            return
        }
        itemsForSahre = ShareableItems(items: [stringToShare])
        AppLogger.shared.info("Prepared sharing content: \(stringToShare)", category: .ui)
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
