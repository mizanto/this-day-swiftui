//
//  EventsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class EventsViewBuilder {
    static func build() -> some View {
        guard let historyService: HistoryServiceProtocol = DIContainer.shared.resolve() else {
            fatalError("HistoryService not registered in DI Container")
        }

        let viewModel = EventsViewModel(networkService: historyService,
                                        router: EventsRouter())
        return EventsView(viewModel: viewModel)
    }
}
