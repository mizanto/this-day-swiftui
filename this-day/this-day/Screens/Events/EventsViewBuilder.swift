//
//  EventsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class EventsViewBuilder {
    static func build() -> some View {
        let viewModel = EventsViewModel()
        let router = EventsRouter()
        return EventsView(viewModel: viewModel, router: router)
    }
}
