//
//  DayViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import Combine

protocol DayViewModelProtocol: ObservableObject {
    var state: ViewState<[any EventProtocol]> { get }
    var title: String { get }
    var subtitle: String { get }
    var itemsForSahre: ShareableItems? { get set }
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
    @Published var selectedCategory: EventCategory = .events {
        didSet {
            updateState(with: selectedCategory)
        }
    }

    private let currentDate: Date = Date()
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var day: DayEntity? {
        didSet {
            guard let day else { return }
            subtitle = day.text
            cacheEvents(for: day)
        }
    }
    private var uiModels: [EventCategory: [any EventProtocol]] = [:]

    init(networkService: NetworkServiceProtocol = NetworkService(),
         storageService: StorageServiceProtocol) {
        self.networkService = networkService
        self.storageService = storageService
    }

    func onAppear() {
        AppLogger.shared.info("Events view appeared", category: .ui)

        title = currentDate.toFormat("MMMM dd")
        let idString = currentDate.toFormat("MM_dd")

        do {
            if let dayEntity = try storageService.fetchDay(id: idString) {
                AppLogger.shared.info("Data found in storage for day with id: \(idString)", category: .ui)
                day = dayEntity
                if state == .initial {
                    selectedCategory = .events
                } else {
                    updateState(with: selectedCategory)
                }
            } else {
                AppLogger.shared.info("No data in storage for id: \(idString). Fetching from network.", category: .ui)
                fetchEvents(for: currentDate)
            }
        } catch {
            AppLogger.shared.error("Error fetching data for day with id: \(idString): \(error)", category: .ui)
            fetchEvents(for: currentDate)
        }
    }

    func onTryAgain() {
        AppLogger.shared.info("Trying to fetch events after error", category: .ui)
        fetchEvents(for: currentDate)
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
        guard let stringToCopy = day?.eventsArray.first(where: { $0.id == id })?.toSharingString() else {
            AppLogger.shared.error("Failed to copy event \(id) to clipboard. No sharing string available.",
                                   category: .ui)
            return
        }
        UIPasteboard.general.string = stringToCopy
        AppLogger.shared.info("Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareEvent(id: UUID) {
        guard let stringToShare = day?.eventsArray.first(where: { $0.id == id })?.toSharingString() else {
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

    private func fetchEvents(for date: Date) {
        AppLogger.shared.info("Starting to fetch events for date: \(date)", category: .ui)

        state = .loading

        networkService.fetchEvents(for: date)
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
                    AppLogger.shared.info("Loaded \(model.general.count) events, \(model.births.count) births, \(model.deaths.count) deaths and \(model.holidays.count) holidays for date: \(date)", category: .ui)

                    self.save(networkModel: model, for: date)
                }
            )
            .store(in: &cancellables)
    }

    private func save(networkModel: DayNetworkModel, for date: Date) {
        do {
            try storageService.saveDay(networkModel: networkModel, for: date)
            if let dayEntity = try storageService.fetchDay(id: date.toFormat("MM_dd")) {
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
        let filteredEvents = events.filter { $0.eventType == type }
        return filteredEvents.map { $0.toDisplayModel() }
    }

    private func cacheEvents(for day: DayEntity?) {
        guard let day else { return }

        uiModels = [
            .events: mapEvents(from: day.eventsArray, for: .general),
            .births: mapEvents(from: day.eventsArray, for: .birth),
            .deaths: mapEvents(from: day.eventsArray, for: .death),
            .holidays: mapEvents(from: day.eventsArray, for: .holiday)
        ]
    }
}
