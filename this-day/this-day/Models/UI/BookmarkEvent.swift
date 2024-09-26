//
//  BookmarkEvent.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//

import Foundation

struct BookmarkEvent: Identifiable {
    let id: UUID
    let date: String
    let title: String
    let subtitle: String?
    let inBookmarks: Bool
    let category: EventCategory

    init(id: UUID = UUID(),
         date: String,
         title: String,
         subtitle: String? = nil,
         inBookmarks: Bool = true,
         category: EventCategory) {
        self.id = id
        self.date = date
        self.title = title
        self.subtitle = subtitle
        self.inBookmarks = inBookmarks
        self.category = category
    }
}
