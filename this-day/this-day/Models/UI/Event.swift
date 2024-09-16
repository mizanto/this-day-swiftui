//
//  Event.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct Event: Identifiable {
    let id = UUID()
    let year: String
    let text: String
    let links: [EventLink]
}
