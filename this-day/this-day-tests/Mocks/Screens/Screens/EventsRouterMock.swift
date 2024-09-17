//
//  EventsRouterMock.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import SwiftUI

@testable import this_day

final class EventsRouterMock: EventsRouterProtocol {
    var didCallViewForEvent = false
    
    func view(for event: Event) -> AnyView {
        didCallViewForEvent = true
        return AnyView(Text("Mock View for Event"))
    }
}
