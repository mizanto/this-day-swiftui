//
//  EventType.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation

enum EventType: String {
    case general
    case birth
    case death
}

extension EventEntity {
    var eventType: EventType {
        get {
            return EventType(rawValue: type) ?? .general
        }
        set {
            type = newValue.rawValue
        }
    }
}
