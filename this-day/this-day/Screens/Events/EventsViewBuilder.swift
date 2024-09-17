//
//  EventsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class EventsViewBuilder {
    static func build(historyService: HistoryServiceProtocol) -> some View {
        let viewModel = EventsViewModel(networkService: historyService,
                                        router: EventsRouter())
        return EventsView(viewModel: viewModel)
    }
}
