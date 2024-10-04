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
    func removeBookmark(for eventID: String)
    func copyToClipboardBookmark(id: String)
    func shareBookmark(id: String)
}

final class BookmarksViewModel: BookmarksViewModelProtocol {
    @Published var state: ViewState<[BookmarkEvent]> = .initial
    @Published var itemsForSahre: ShareableItems?
    @Published var showSnackbar = false
    var snackbarMessage: String { LocalizedString("message.snackbar.copied") }

    private let dataRepository: DataRepositoryProtocol
    private let localizationManager: any LocalizationManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    private var bookmarks: [BookmarkEntity] = [] {
        didSet { cacheBookmarks(bookmarks) }
    }
    private var uiModels: [BookmarkEvent] = []
    private var language: String { localizationManager.currentLanguage }

    init(dataRepository: DataRepositoryProtocol,
         localizationManager: any LocalizationManagerProtocol) {
        self.dataRepository = dataRepository
        self.localizationManager = localizationManager
    }

    func onAppear() {
        AppLogger.shared.debug("BookmarksViewModel: onAppear", category: .ui)
        state = .loading

        dataRepository.fetchBookmarks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("Failed to fetch bookmarks: \(error)", category: .ui)
                        self.state = .error("Failed to fetch bookmarks")
                    }
                },
                receiveValue: { [weak self] bookmarks in
                    guard let self else { return }
                    AppLogger.shared.debug("Fetched \(bookmarks.count) bookmarks", category: .ui)
                    self.bookmarks = bookmarks
                    self.state = .data(uiModels)
                }
            )
            .store(in: &cancellables)
    }

    func removeBookmark(for id: String) {
        dataRepository.toggleBookmark(for: id)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] () -> AnyPublisher<[BookmarkEntity], RepositoryError> in
                guard let self else {
                    return Fail(error: .unknownError("Self is nil"))
                        .eraseToAnyPublisher()
                }
                return self.dataRepository.fetchBookmarks().eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("Failed to remove bookmark: \(error)", category: .ui)
                    }
                },
                receiveValue: { [weak self] bookmarks in
                    guard let self else { return }
                    AppLogger.shared.debug("Removed bookmark: \(id)", category: .ui)

                    self.bookmarks = bookmarks
                    state = .data(uiModels)

                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)
                }
            )
            .store(in: &cancellables)
    }

    func copyToClipboardBookmark(id: String) {
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

    func shareBookmark(id: String) {
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
