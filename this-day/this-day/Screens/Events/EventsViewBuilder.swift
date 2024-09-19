//
//  EventsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class EventsViewBuilder {
    static func build(wikipediaService: WikipediaService) -> some View {
//        let viewModel = EventsViewModel(networkService: historyService,
//                                        router: EventsRouter())
        let viewModel = EventsViewModel(wikipediaService: wikipediaService,
                                        router: EventsRouter())
        return EventsView(viewModel: viewModel)
    }
}
