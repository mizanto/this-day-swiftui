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
}

final class DayViewModel: DayViewModelProtocol {
    @Published var state: ViewState<[any EventProtocol]> = .loading
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var itemsForSahre: ShareableItems?
    @Published var selectedCategory: EventCategory = .events {
        didSet {
            selectCategory(selectedCategory)
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
            if let dayEntity = try storageService.fetchDay(for: idString) {
                AppLogger.shared.info("Data found in storage for day with id: \(idString)", category: .ui)
                day = dayEntity
                selectedCategory = .events
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

    func toggleBookmark(for eventID: UUID) {
        do {
            guard let event = try storageService.fetchEvent(for: eventID) else {
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
                selectCategory(selectedCategory)
            }
        } catch {
            AppLogger.shared.error("Failed to toggle bookmark for event \(eventID): \(error)", category: .ui)
        }
    }

    func copyToClipboardEvent(id: UUID) {
        guard let event = try? storageService.fetchEvent(for: id) else {
            AppLogger.shared.error("Failed to copy event \(id) to clipboard. Event not found.", category: .ui)
            return
        }

        let stringToCopy = event.toSharingString(for: currentDate)
        UIPasteboard.general.string = stringToCopy
        AppLogger.shared.info("Event \(id) copied to clipboard: \(stringToCopy)", category: .ui)
    }

    func shareEvent(id: UUID) {
        AppLogger.shared.debug("Sharing event \(id)")

        guard let event = try? storageService.fetchEvent(for: id) else {
            AppLogger.shared.error("Failed to fetch event for sharing with id \(id)", category: .ui)
            return
        }

        let shareContent = event.toSharingString(for: currentDate)
        itemsForSahre = ShareableItems(items: [shareContent])
        AppLogger.shared.info("Prepared sharing content: \(shareContent)", category: .ui)
    }

    private func save(networkModel: DayNetworkModel, for date: Date) {
        do {
            try storageService.saveDay(networkModel: networkModel, for: date)
            if let dayEntity = try storageService.fetchDay(for: date.toFormat("MM_dd")) {
                self.day = dayEntity
                self.selectedCategory = .events
            }
        } catch {
            AppLogger.shared.error("Failed to save or fetch events for date: \(date). Error: \(error)", category: .ui)
            self.state = .error("Failed to load events. Please try again.")
        }
    }

    private func selectCategory(_ category: EventCategory) {
        AppLogger.shared.debug("Selecting category <\(category.rawValue)>")

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
