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
    var selectedCategory: EventCategory { get set }

    func onAppear()
    func onTryAgain()
}

final class DayViewModel: DayViewModelProtocol {
    @Published var state: ViewState<[any EventProtocol]> = .loading
    @Published var title: String = ""
    @Published var subtitle: String = ""
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
                subtitle = day.text ?? ""
            }
        }

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
            let dayEntity = try storageService.fetchDay(for: idString)
            AppLogger.shared.info("Data found in storage for id: \(idString)", category: .ui)
            day = dayEntity
            selectedCategory = .events
        } catch {
            AppLogger.shared.info("No data in storage for id: \(idString). Fetching from network.", category: .ui)
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
                receiveValue: { [weak self] dayNetwork in
                    guard let self else { return }
                    // swiftlint:disable:next line_length
                    AppLogger.shared.info("Loaded \(dayNetwork.general.count) events, \(dayNetwork.births.count) births, \(dayNetwork.deaths.count) deaths and \(dayNetwork.holidays.count) holidays for date: \(date)", category: .ui)

                    do {
                        try self.storageService.saveDay(networkModel: dayNetwork, for: date)
                        let dayEntity = try self.storageService.fetchDay(for: date.toFormat("MM_dd"))
                        self.day = dayEntity
                        self.selectedCategory = .events
                    } catch {
                        AppLogger.shared.error("Failed to save or fetch events for date: \(date). Error: \(error)",
                                               category: .ui)
                        self.state = .error("Failed to load events. Please try again.")
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func selectCategory(_ category: EventCategory) {
        guard let day else { return }
        AppLogger.shared.debug("Selecting category <\(category.rawValue)>")

        let events: [any EventProtocol]

        switch category {
        case .events:
            events = mapEvents(from: day.eventsArray, for: .general)
        case .births:
            events = mapEvents(from: day.eventsArray, for: .birth)
        case .deaths:
            events = mapEvents(from: day.eventsArray, for: .death)
        case .holidays:
            events = mapEvents(from: day.eventsArray, for: .holiday)
        }

        state = .data(events)
    }
    
    private func mapEvents(from events: [EventEntity], for type: EventType) -> [any EventProtocol] {
        let filteredEvents = events.filter { $0.eventType == type }
        return filteredEvents.map { $0.toDisplayModel() }
    }
}

//private extension Array where Element == EventNetworkModel {
//
//    func mapToShortEvents() -> [ShortEvent] {
//        compactMap { event in
//            return ShortEvent(title: event.title)
//        }
//    }
//
//    func mapToDefaultEvents() -> [DefaultEvent] {
//        compactMap { event in
//            guard let year = event.year else { return nil}
//            return DefaultEvent(year: year, title: event.title)
//        }
//    }
//
//    func mapToExtendedEvents() -> [ExtendedEvent] {
//        compactMap { event in
//            guard let year = event.year, let subtitle = event.additional else { return nil}
//            return ExtendedEvent(year: year, title: event.title, subtitle: subtitle)
//        }
//    }
//}
