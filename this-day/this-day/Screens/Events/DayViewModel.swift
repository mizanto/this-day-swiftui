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
    private var cancellables = Set<AnyCancellable>()
    private var day: DayNetworkModel? {
        didSet {
            guard let day else { return }
            subtitle = day.text
        }
    }

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func onAppear() {
        AppLogger.shared.info("Events view appeared", category: .ui)

        title = currentDate.toFormat("MMMM dd")
        fetchEvents(for: currentDate)
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
                receiveValue: { [weak self] day in
                    // swiftlint:disable:next line_length
                    AppLogger.shared.info("Loaded \(day.events.count) events, \(day.births.count) births, \(day.deaths.count) deaths and \(day.holidays.count) holidays for date: \(date)", category: .ui)
                    self?.day = day
                    self?.selectedCategory = .events
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
            events = day.events.mapToDefaultEvents()
        case .births:
            events = day.births.mapToExtendedEvents()
        case .deaths:
            events = day.deaths.mapToExtendedEvents()
        case .holidays:
            events = day.holidays.mapToShortEvents()
        }

        state = .data(events)
    }
}

private extension Array where Element == EventNetworkModel {

    func mapToShortEvents() -> [ShortEvent] {
        compactMap { event in
            guard let title = event.title else { return nil }
            return ShortEvent(title: title)
        }
    }

    func mapToDefaultEvents() -> [DefaultEvent] {
        compactMap { event in
            guard let year = event.year, let title = event.title else { return nil}
            return DefaultEvent(year: year, title: title)
        }
    }

    func mapToExtendedEvents() -> [ExtendedEvent] {
        compactMap { event in
            guard let year = event.year, let title = event.title,
                  let subtitle = event.additional else { return nil}
            return ExtendedEvent(year: year, title: title, subtitle: subtitle)
        }
    }
}
