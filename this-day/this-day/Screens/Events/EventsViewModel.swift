//
//  EventsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation
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
}

class EventsViewModel: EventsViewModelProtocol {
    @Published var state: ViewState = .loading
    @Published var title: String = ""

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
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
}
