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
    private let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private var events: [EventDataModel] = [] {
        didSet {
            cacheEvents(events)
            state = .data(uiModels)
        }
    }
    private var uiModels: [BookmarkEvent] = []
    private var language: String { localizationManager.currentLanguage }

    init(dataRepository: DataRepositoryProtocol,
         localizationManager: any LocalizationManagerProtocol,
         analyticsService: AnalyticsServiceProtocol) {
        self.dataRepository = dataRepository
        self.localizationManager = localizationManager
        self.analyticsService = analyticsService
    }

    func onAppear() {
        state = .loading
        dataRepository.fetchBookmarkedEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("[Bookmarks View]: Failed to fetch bookmarked events: \(error)",
                                               category: .ui)
                        self.state = .error("Failed to fetch bookmarked events")
                    }
                },
                receiveValue: { [weak self] events in
                    guard let self else { return }
                    AppLogger.shared.debug("[Bookmarks View]: Fetched \(events.count) bookmarks", category: .ui)

                    self.events = events
                }
            )
            .store(in: &cancellables)
    }

    func removeBookmark(for id: String) {
        dataRepository.toggleBookmark(for: id)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] () -> AnyPublisher<[EventDataModel], RepositoryError> in
                guard let self else {
                    return Fail(error: .unknownError("Self is nil"))
                        .eraseToAnyPublisher()
                }
                return self.dataRepository.fetchBookmarkedEvents().eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("[Bookmarks View]: Failed to remove bookmark: \(error)", category: .ui)
                    }
                },
                receiveValue: { [weak self] events in
                    guard let self else { return }
                    AppLogger.shared.debug("[Bookmarks View]: Removed bookmark: \(id)", category: .ui)

                    self.events = events

                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)

                    self.analyticsService.logEvent(.removeBookmark, parameters: ["source": "bookmarks"])
                }
            )
            .store(in: &cancellables)
    }

    func copyToClipboardBookmark(id: String) {
        let stringToCopy = events.first(where: { $0.id == id })?.toSharingString(language: language)
        guard let stringToCopy else {
            AppLogger.shared.error(
                "[Bookmarks View]: Failed to copy event \(id) to clipboard. No sharing string available.",
                category: .ui)
            return
        }
        UIPasteboard.general.string = stringToCopy
        showSnackbar = true

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()

        analyticsService.logEvent(.copyEvent, parameters: ["source": "bookmarks"])

        AppLogger.shared.debug("[Bookmarks View]: Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareBookmark(id: String) {
        let stringToShare = events.first(where: { $0.id == id })?.toSharingString(language: language)
        guard let stringToShare else {
            AppLogger.shared.error(
                "[Bookmarks View]: Failed to share event \(id) to social media. No sharing string available.",
                category: .ui)
            return
        }
        itemsForSahre = ShareableItems(items: [stringToShare])

        analyticsService.logEvent(.shareEvent, parameters: ["source": "bookmarks"])

        AppLogger.shared.debug("[Bookmarks View]: Prepared sharing content: \(stringToShare)", category: .ui)
    }

    private func cacheEvents(_ events: [EventDataModel]) {
        uiModels = events.map { event in
            return BookmarkEvent(
                id: event.id,
                date: event.stringDate ?? "??????",
                language: event.language,
                title: event.title,
                subtitle: event.subtitle,
                inBookmarks: true,
                category: EventCategory.from(event.type)
            )
        }
    }
}
