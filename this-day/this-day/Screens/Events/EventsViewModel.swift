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
    case loaded([Event])
    case error(String)
}

protocol EventsViewModelProtocol: ObservableObject {
    var state: ViewState { get }
    var title: String { get }
    func fetchEvents(for date: Date)
//    func view(for: Event) -> AnyView
}

//class EventsViewModel: EventsViewModelProtocol {
//    @Published var state: ViewState = .loading
//    @Published var title: String = ""
//
//    private let router: EventsRouterProtocol
//    private let networkService: HistoryServiceProtocol
//    private var cancellables = Set<AnyCancellable>()
//
//    init(networkService: HistoryServiceProtocol = HistoryService(),
//         router: EventsRouterProtocol) {
//        self.networkService = networkService
//        self.router = router
//    }
//
//    func fetchEvents(for date: Date) {
//        AppLogger.shared.info("Starting to fetch events for date: \(date)", category: .ui)
//
//        state = .loading
//        title = date.toFormat("MMMM dd")
//
//        networkService.fetchEvents(for: date)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    switch completion {
//                    case .failure(let error):
//                        AppLogger.shared.error("Failed to load events for date: \(date). Error: \(error)",
//                                               category: .ui)
//                        self?.state = .error("Failed to load events. Please try again.")
//                    case .finished:
//                        AppLogger.shared.info("Successfully finished fetching events for date: \(date)",
//                                              category: .ui)
//                    }
//                },
//                receiveValue: { [weak self] events in
//                    AppLogger.shared.info("Loaded \(events.count) events for date: \(date)", category: .ui)
//                    self?.state = .loaded(events.map { $0.toUIModel() })
//                }
//            )
//            .store(in: &cancellables)
//    }
//
//    func view(for event: Event) -> AnyView {
//        return router.view(for: event)
//    }
//}

class EventsViewModel: EventsViewModelProtocol {
    @Published var state: ViewState = .loading
    @Published var title: String = ""

    private let router: EventsRouterProtocol
    private let wikipediaService: WikipediaService
    private var cancellables = Set<AnyCancellable>()

    init(wikipediaService: WikipediaService = WikipediaService(),
         router: EventsRouterProtocol) {
        self.wikipediaService = wikipediaService
        self.router = router
    }

    func fetchEvents(for date: Date) {
        AppLogger.shared.info("Starting to fetch events for date: \(date)", category: .ui)

        state = .loading
        title = date.toFormat("MMMM dd")

        wikipediaService.fetchEvents(for: date)
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
                receiveValue: { [weak self] wikipediaDay in
                    AppLogger.shared.info("Loaded \(wikipediaDay.events.count) events for date: \(date)", category: .ui)
                    // Преобразование WikipediaEvent в Event
                    let events = wikipediaDay.events.map { $0.toEvent() }
                    self?.state = .loaded(events)
                }
            )
            .store(in: &cancellables)
    }

    // Этот метод используется для перехода на экран с деталями события
//    func view(for event: Event) -> AnyView {
//        router.routeToEventDetail(for: event)
//    }
}

extension WikipediaEvent {
    // Преобразование из WikipediaEvent в Event
    func toEvent() -> Event {
        return Event(year: title, text: text, links: [])
    }
}
