//
//  EventsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation
import Combine

let sampleEvents = [
    HistoricalEvent(
        year: "81",
        text: "Domitian became Emperor of the Roman Empire upon the death of his brother Titus.",
        links: [
            EventLink(title: "Domitian", link: "https://wikipedia.org/wiki/Domitian"),
            EventLink(title: "Roman Empire", link: "https://wikipedia.org/wiki/Roman_Empire"),
            EventLink(title: "Titus", link: "https://wikipedia.org/wiki/Titus")
        ]
    ),
    HistoricalEvent(
        year: "629",
        text: "Emperor Heraclius enters Constantinople in triumph after his victory over the Persian Empire.",
        links: [
            EventLink(title: "Heraclius", link: "https://wikipedia.org/wiki/Heraclius"),
            EventLink(title: "Constantinople", link: "https://wikipedia.org/wiki/Constantinople"),
            EventLink(title: "Sasanian Empire", link: "https://wikipedia.org/wiki/Sasanian_Empire")
        ]
    )
]

enum ViewState {
    case loading
    case loaded([HistoricalEvent])
    case error(String)
}

protocol EventsViewModelProtocol: ObservableObject {
    var state: ViewState { get }
    var title: String { get }
    func fetchEvents()
}

class EventsViewModel: EventsViewModelProtocol {
    @Published var state: ViewState = .loading
    @Published var title: String = "September 14"

    private var cancellables = Set<AnyCancellable>()

    func fetchEvents() {
        state = .loading

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let success = Bool.random()

            if success {
                self.state = .loaded(sampleEvents)
            } else {
                self.state = .error("Failed to load events. Please try again.")
            }
        }
    }
}
