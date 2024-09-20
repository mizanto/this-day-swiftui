//
//  EventsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import Combine

enum ViewState {
    case loading
    case loaded(Day)
    case error(String)
}

enum EventCategory: String, CaseIterable, Identifiable {
    case events = "Events"
    case births = "Births"
    case deaths = "Deaths"
    case holidays = "Holidays"

    var id: String { self.rawValue }
}

protocol EventsViewModelProtocol: ObservableObject {
    var state: ViewState { get }
    var title: String { get }
    var subtitle: String { get }
    var selectedCategory: EventCategory { get set }

    func onAppear()
    func onTryAgain()
}

class EventsViewModel: EventsViewModelProtocol {
    @Published var state: ViewState = .loading
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var selectedCategory: EventCategory = .events

    private let router: EventsRouterProtocol
    private let networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()

    private var day: DayNetworkModel? {
        didSet {
            guard let day else { return }
            subtitle = day.text
        }
    }

    init(networkService: NetworkService = NetworkService(),
         router: EventsRouterProtocol) {
        self.networkService = networkService
        self.router = router

        $selectedCategory
            .sink { [weak self] category in
                self?.selectCategory(category)
            }
            .store(in: &cancellables)
    }

    func onAppear() {
        AppLogger.shared.info("Events view appeared", category: .ui)
        fetchEvents(for: Date())
    }

    func onTryAgain() {
        AppLogger.shared.info("Trying to fetch events", category: .ui)
        fetchEvents(for: Date())
    }

    private func fetchEvents(for date: Date) {
        AppLogger.shared.info("Starting to fetch events for date: \(date)", category: .ui)

        state = .loading
        title = date.toFormat("MMMM dd")

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
                    self?.selectCategory(.events)
                }
            )
            .store(in: &cancellables)
    }

    private func selectCategory(_ category: EventCategory) {
        guard let day else { return }

        let events: [Event]

        switch category {
        case .events:
            events = day.events.map(Event.init(from:))
        case .births:
            events = day.births.map(Event.init(from:))
        case .deaths:
            events = day.deaths.map(Event.init(from:))
        case .holidays:
            events = day.holidays.map(Event.init(from:))
        }

        state = .loaded(
            Day(text: day.text, events: events)
        )
    }
}
