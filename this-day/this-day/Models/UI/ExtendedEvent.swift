//
//  ExtendedEvent.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import Foundation

struct ExtendedEvent: EventProtocol, Equatable {
    let id: String
    let year: String
    let title: String
    let subtitle: String?
    let inBookmarks: Bool

    init(id: String, year: String, title: String, subtitle: String? = nil, inBookmarks: Bool) {
        self.id = id
        self.year = year
        self.title = title
        self.subtitle = subtitle
        self.inBookmarks = inBookmarks
    }
}
