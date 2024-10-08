//
//  DayViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import Combine
import UIKit

protocol DayViewModelProtocol: ObservableObject {
    var state: ViewState<[Event]> { get }
    var title: String { get }
    var subtitle: String { get }
    var snackbarMessage: String { get }
    var itemsForSahre: ShareableItems? { get set }
    var showSnackbar: Bool { get set }
    var selectedCategory: EventCategory { get set }

    func onAppear()
    func onTryAgain()
    func toggleBookmark(for eventID: String)
    func copyToClipboardEvent(id: String)
    func shareEvent(id: String)
    func onCompleteShare()
}

final class DayViewModel: DayViewModelProtocol {
    @Published var state: ViewState<[Event]> = .initial
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var itemsForSahre: ShareableItems?
    @Published var showSnackbar = false
    @Published var selectedCategory: EventCategory = .events {
        didSet {
            updateState(with: selectedCategory)
        }
    }
    var snackbarMessage: String { LocalizedString("message.snackbar.copied") }

    private var currentDate: Date = Date()
    private var dataRepository: DataRepositoryProtocol
    private let localizationManager: any LocalizationManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var day: DayDataModel? {
        didSet {
            guard let day else { return }
            cacheEvents(for: day)
        }
    }
    private var uiModels: [EventCategory: [Event]] = [:]
    private var language: String { localizationManager.currentLanguage }

    init(dataRepository: DataRepositoryProtocol,
         localizationManager: any LocalizationManagerProtocol) {
        self.dataRepository = dataRepository
        self.localizationManager = localizationManager
    }

    func onAppear() {
        updateData()
    }

    private func updateData() {
        AppLogger.shared.debug("[Events View]: Updating events data", category: .ui)
        currentDate = Date()
        title = currentDate.toLocalizedDayMonth(language: language)
        fetchEvents(for: currentDate, language: language)
    }

    private func fetchEvents(for date: Date, language: String) {
        state = .loading
        dataRepository.fetchDay(date: date, language: language)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        guard let self else { return }
                        AppLogger.shared.error(
                            "[Events View]: Failed to load events for date: \(date). Error: \(error)", category: .ui)
                        self.state = .error("Failed to load events. Please try again.")
                    }
                },
                receiveValue: { [weak self] model in
                    guard let self else { return }
                    AppLogger.shared.debug("[Events View]: Loaded events for date: \(date)", category: .ui)
                    self.day = model
                    selectedCategory = .events
                }
            )
            .store(in: &cancellables)
    }

    func onTryAgain() {
        AppLogger.shared.debug("[Events View]: Trying to fetch events after error", category: .ui)
        fetchEvents(for: currentDate, language: language)
    }

    func toggleBookmark(for eventID: String) {
        dataRepository.toggleBookmark(for: eventID)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        AppLogger.shared.debug("[Events View]: Failed to toggle bookmark for event \(eventID).",
                                               category: .ui)
                        // TODO: show snackbar with error
                    }
                },
                receiveValue: {
                    AppLogger.shared.debug(
                        "[Events View]: Successfully toggled bookmark for event \(eventID)", category: .ui)
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)
                }
            )
            .store(in: &cancellables)
    }

    func copyToClipboardEvent(id: String) {
        let stringToCopy = day?.events(for: selectedCategory)
            .first(where: { $0.id == id })?.toSharingString(language: language)

        guard let stringToCopy else {
            AppLogger.shared.error(
                "[Events View]: Failed to copy event \(id) to clipboard. No sharing string available.", category: .ui)
            return
        }

        UIPasteboard.general.string = stringToCopy
        showSnackbar = true

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()

        AppLogger.shared.debug("[Events View]: Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareEvent(id: String) {
        let stringToShare = day?.events(for: selectedCategory)
            .first(where: { $0.id == id })?.toSharingString(language: language)
        guard let stringToShare else {
            AppLogger.shared.error(
                "[Events View]: Failed to share event \(id) to social media. No sharing string available.",
                category: .ui)
            return
        }
        itemsForSahre = ShareableItems(items: [stringToShare])
        AppLogger.shared.debug("[Events View]: Prepared sharing content: \(stringToShare)", category: .ui)
    }

    func onCompleteShare() {
        itemsForSahre = nil
    }

    private func updateState(with category: EventCategory) {
        AppLogger.shared.debug("[Events View]: Updating state with category: \(category)")
        let events = uiModels[category] ?? []
        state = .data(events)
    }

    private func cacheEvents(for day: DayDataModel?) {
        guard let day else { return }
        uiModels = [
            .events: day.general.reversed().map { $0.toDisplayModel() },
            .births: day.births.reversed().map { $0.toDisplayModel() },
            .deaths: day.deaths.reversed().map { $0.toDisplayModel() }
        ]
    }
}

private extension DayDataModel {
    func events(for category: EventCategory) -> [EventDataModel] {
        switch category {
        case .events: general
        case .births: births
        case .deaths: deaths
        }
    }
}
