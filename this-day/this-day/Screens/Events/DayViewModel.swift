//
//  DayViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import Combine

protocol DayViewModelProtocol: ObservableObject {
    var state: ViewState<[Event]> { get }
    var title: String { get }
    var subtitle: String { get }
    var selectedCategory: EventCategory { get set }

    func onAppear()
    func onTryAgain()
}

final class DayViewModel: DayViewModelProtocol {
    @Published var state: ViewState<[Event]> = .loading
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
                    AppLogger.shared.info("Loaded \(day.events.count) events for date: \(date)", category: .ui)
                    self?.day = day
                    self?.selectedCategory = .events
                }
            )
            .store(in: &cancellables)
    }

    private func selectCategory(_ category: EventCategory) {
        guard let day else { return }
        
        AppLogger.shared.debug("Selecting category \(category.rawValue)")

        let events: [Event]

        switch category {
        case .events:
            events = day.events.mapToEvents()
        case .births:
            events = day.births.mapToEvents()
        case .deaths:
            events = day.deaths.mapToEvents()
        case .holidays:
            events = day.holidays.mapToEvents()
        }

        state = .data(events)
    }
}

private extension Array where Element == EventNetworkModel {
    func mapToEvents() -> [Event] {
        map(Event.init(from:))
    }
}
