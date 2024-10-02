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
    var state: ViewState<[any EventProtocol]> { get }
    var title: String { get }
    var subtitle: String { get }
    var snackbarMessage: String { get }
    var itemsForSahre: ShareableItems? { get set }
    var showSnackbar: Bool { get set }
    var selectedCategory: EventCategory { get set }

    func onAppear()
    func onTryAgain()
    func toggleBookmark(for eventID: UUID)
    func copyToClipboardEvent(id: UUID)
    func shareEvent(id: UUID)
    func onCompleteShare()
}

final class DayViewModel: DayViewModelProtocol {
    @Published var state: ViewState<[any EventProtocol]> = .initial
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
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private let localizationManager: any LocalizationManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var day: DayEntity? {
        didSet {
            guard let day else { return }
            subtitle = day.text
            cacheEvents(for: day)
        }
    }
    private var uiModels: [EventCategory: [any EventProtocol]] = [:]
    private var language: String { localizationManager.currentLanguage }

    init(networkService: NetworkServiceProtocol,
         storageService: StorageServiceProtocol,
         localizationManager: any LocalizationManagerProtocol) {
        self.networkService = networkService
        self.storageService = storageService
        self.localizationManager = localizationManager
    }

    func onAppear() {
        AppLogger.shared.info("Events view appeared", category: .ui)

        currentDate = Date()
        title = currentDate.toLocalizedDayMonth(language: language)
        let dayID = DayEntity.createID(date: currentDate, language: language)

        do {
            if let dayEntity = try storageService.fetchDay(id: dayID) {
                AppLogger.shared.info("Data found in storage for day with id: \(dayID)", category: .ui)
                day = dayEntity
                if state == .initial {
                    selectedCategory = .events
                } else {
                    updateState(with: selectedCategory)
                }
            } else {
                AppLogger.shared.info("No data in storage for id: \(dayID). Fetching from network.", category: .ui)
                fetchEvents(for: currentDate, language: language)
            }
        } catch {
            AppLogger.shared.error("Error fetching data for day with id: \(dayID): \(error)", category: .ui)
            fetchEvents(for: currentDate, language: language)
        }
    }

    func onTryAgain() {
        AppLogger.shared.info("Trying to fetch events after error", category: .ui)
        fetchEvents(for: currentDate, language: language)
    }

    func toggleBookmark(for eventID: UUID) {
        do {
            guard let event = try storageService.fetchEvent(id: eventID) else {
                AppLogger.shared.error("Failed to toggle bookmark for event \(eventID). Event not found.",
                                       category: .ui)
                return
            }

            // Check if the event is currently a favorite
            if event.inBookmarks {
                try storageService.removeFromBookmarks(event: event)
            } else {
                try storageService.addToBookmarks(event: event)
            }
            AppLogger.shared.info("Successfully toggled bookmark for event \(eventID)", category: .database)

            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)

            if let index = day?.eventsArray.firstIndex(where: { $0.id == eventID }) {
                day?.replaceEvents(at: index, with: event)
                cacheEvents(for: day)
                updateState(with: selectedCategory)
            }
        } catch {
            AppLogger.shared.error("Failed to toggle bookmark for event \(eventID): \(error)", category: .ui)
        }
    }

    func copyToClipboardEvent(id: UUID) {
        let event = day?.eventsArray.first(where: { $0.id == id })
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

    func shareEvent(id: UUID) {
        let event = day?.eventsArray.first(where: { $0.id == id })
        guard let stringToShare = event?.toSharingString(language: language) else {
            AppLogger.shared.error("Failed to share event \(id) to social media. No sharing string available.",
                                   category: .ui)
            return
        }
        itemsForSahre = ShareableItems(items: [stringToShare])
        AppLogger.shared.info("Prepared sharing content: \(stringToShare)", category: .ui)
    }

    func onCompleteShare() {
        itemsForSahre = nil
    }

    private func fetchEvents(for date: Date, language: String) {
        AppLogger.shared.info("Starting to fetch events for date: \(date)", category: .ui)

        state = .loading

        networkService.fetchEvents(for: date, language: language)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        AppLogger.shared.error("Failed to load events for date: \(date). Error: \(error)",
                                               category: .ui)
                        self?.state = .error("Failed to load events. Please try again.")
                    case .finished:
                        AppLogger.shared.info("Successfully finished fetching events for date: \(date)",
                                              category: .ui)
                    }
                },
                receiveValue: { [weak self] model in
                    guard let self else { return }
                    // swiftlint:disable:next line_length
                    AppLogger.shared.info("Loaded \(model.general.count) events, \(model.births.count) births and \(model.deaths.count) deaths for date: \(date)", category: .ui)

                    self.save(networkModel: model, for: date)
                }
            )
            .store(in: &cancellables)
    }

    private func save(networkModel: DayNetworkModel, for date: Date) {
        do {
            try storageService.saveDay(networkModel: networkModel,
                                       for: date,
                                       language: language)
            let id = DayEntity.createID(date: currentDate, language: language)
            if let dayEntity = try storageService.fetchDay(id: id) {
                day = dayEntity
                selectedCategory = .events
            }
        } catch {
            AppLogger.shared.error("Failed to save or fetch events for date: \(date). Error: \(error)", category: .ui)
            self.state = .error("Failed to load events. Please try again.")
        }
    }

    private func updateState(with category: EventCategory) {
        AppLogger.shared.debug("Updating state with category: \(category)")

        let events = uiModels[category] ?? []
        state = .data(events)
    }

    private func mapEvents(from events: [EventEntity], for type: EventType) -> [any EventProtocol] {
        return events.compactMap { event in
            guard event.eventType == type else { return nil }
            return event.toDisplayModel()
        }
        .reversed()
    }

    private func cacheEvents(for day: DayEntity?) {
        guard let day else { return }

        uiModels = [
            .events: mapEvents(from: day.eventsArray, for: .general),
            .births: mapEvents(from: day.eventsArray, for: .birth),
            .deaths: mapEvents(from: day.eventsArray, for: .death)
        ]
    }
}
