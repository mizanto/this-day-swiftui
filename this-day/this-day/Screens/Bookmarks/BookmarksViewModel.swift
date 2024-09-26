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

    private var events: [EventEntity] = [] {
        didSet {
            cacheEvents(events)
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
            events = try storageService.fetchBookmarks().reversed()
            state = .data(uiModels)
            AppLogger.shared.debug("Fetched \(events.count) bookmarks", category: .ui)
        } catch {
            AppLogger.shared.error("Failed to fetch bookmarks: \(error)", category: .ui)
            state = .error("Failed to fetch bookmarks")
        }
    }

    func removeBookmark(for eventID: UUID) {
        guard let event = events.first(where: { $0.id == eventID }) else {
            AppLogger.shared.error("Failed to remove bookmark: Event not found", category: .ui)
            return
        }
        do {
            try storageService.removeFromBookmarks(event: event)
            events = try storageService.fetchBookmarks()
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

    private func cacheEvents(_ events: [EventEntity]) {
        uiModels = events.map { event in
            // TODO: Update after entity fix
            let dateString = event.eventType == .holiday ? "September 26" : "September 26, \(event.year ?? "")"

            return BookmarkEvent(
                id: event.id,
                date: dateString,
                title: event.title,
                subtitle: event.subtitle,
                inBookmarks: true,
                category: EventCategory.from(event.eventType)
            )
        }
    }
}
