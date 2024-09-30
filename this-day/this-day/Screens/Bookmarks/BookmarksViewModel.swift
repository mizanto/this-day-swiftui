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
    var snackbarMessage: String { get }
    var showSnackbar: Bool { get set }

    func onAppear()
    func removeBookmark(for eventID: UUID)
    func copyToClipboardBookmark(id: UUID)
    func shareBookmark(id: UUID)
}

final class BookmarksViewModel: BookmarksViewModelProtocol {
    @Published var state: ViewState<[BookmarkEvent]> = .initial
    @Published var itemsForSahre: ShareableItems?
    @Published var showSnackbar = false
    var snackbarMessage: String { LocalizedString("message.snackbar.copied") }

    private let storageService: StorageServiceProtocol
    private let localizationManager: any LocalizationManagerProtocol

    private var bookmarks: [BookmarkEntity] = [] {
        didSet { cacheBookmarks(bookmarks) }
    }
    private var uiModels: [BookmarkEvent] = []
    private var language: String { localizationManager.currentLanguage }

    init(storageService: StorageServiceProtocol,
         localizationManager: any LocalizationManagerProtocol) {
        self.storageService = storageService
        self.localizationManager = localizationManager
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

            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        } catch {
            AppLogger.shared.error("Failed to remove bookmark: \(error)", category: .ui)
        }
    }

    func copyToClipboardBookmark(id: UUID) {
        let event = bookmarks.first(where: { $0.id == id })?.event
        guard let stringToCopy = event?.toSharingString(language: language) else {
            AppLogger.shared.error("Failed to copy event \(id) to clipboard. No sharing string available.",
                                   category: .ui)
            return
        }
        UIPasteboard.general.string = stringToCopy
        showSnackbar = true

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()

        AppLogger.shared.info("Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareBookmark(id: UUID) {
        let event = bookmarks.first(where: { $0.id == id })?.event
        guard let stringToShare = event?.toSharingString(language: language) else {
            AppLogger.shared.error("Failed to share event \(id) to social media. No sharing string available.",
                                   category: .ui)
            return
        }
        itemsForSahre = ShareableItems(items: [stringToShare])
        AppLogger.shared.info("Prepared sharing content: \(stringToShare)", category: .ui)
    }

    private func cacheBookmarks(_ bookmarks: [BookmarkEntity]) {
        uiModels = bookmarks.compactMap { bookmark in
            guard let event = bookmark.event, let day = event.day else { return nil }

            return BookmarkEvent(
                id: bookmark.id,
                date: event.stringDate(language: day.language) ?? "??????",
                language: day.language,
                title: event.title,
                subtitle: event.subtitle,
                inBookmarks: true,
                category: EventCategory.from(event.eventType)
            )
        }
    }
}
