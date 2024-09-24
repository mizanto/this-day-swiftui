//
//  DefaultEvent.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import Foundation

struct DefaultEvent: EventProtocol {
    let id: UUID
    let year: String
    let title: String
    
    init(id: UUID = UUID(), year: String, title: String) {
        self.id = id
        self.year = year
        self.title = title
    }
}
