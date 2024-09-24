//
//  ExtendedEvent.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import Foundation

struct ExtendedEvent: EventProtocol {
    let id: UUID
    let year: String
    let title: String
    let subtitle: String

    init(id: UUID = UUID(), year: String, title: String, subtitle: String) {
        self.id = id
        self.year = year
        self.title = title
        self.subtitle = subtitle
    }
}
