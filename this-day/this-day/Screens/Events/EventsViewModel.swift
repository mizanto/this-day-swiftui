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
    func view(for: Event) -> AnyView
}

class EventsViewModel: EventsViewModelProtocol {
    @Published var state: ViewState = .loading
    @Published var title: String = ""

    private let router: EventsRouterProtocol

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(networkService: NetworkServiceProtocol = NetworkService(),
         router: EventsRouterProtocol) {
        self.networkService = networkService
        self.router = router
    }

    func fetchEvents(for date: Date) {
        state = .loading

        title = date.toFormat("MMMM dd")

        networkService.fetchEvents(for: date)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure:
                        self?.state = .error("Failed to load events. Please try again.")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] events in
                    self?.state = .loaded(events.map { $0.toUIModel() })
                }
            )
            .store(in: &cancellables)
    }

    func view(for event: Event) -> AnyView {
        router.view(for: event)
    }
}
