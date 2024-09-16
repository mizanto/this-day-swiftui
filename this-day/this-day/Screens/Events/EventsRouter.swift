//
//  EventsRouter.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI
import Foundation

protocol EventsRouterProtocol {
    func view(for event: Event) -> AnyView
}

final class EventsRouter: EventsRouterProtocol {
    func view(for event: Event) -> AnyView {
        AnyView(EventDetailView(event: event))
    }
}
