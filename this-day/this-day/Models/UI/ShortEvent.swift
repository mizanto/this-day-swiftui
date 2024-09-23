//
//  Event.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

protocol EventProtocol: Identifiable {
    var id: UUID { get }
}

struct ShortEvent: EventProtocol {
    let id = UUID()
    let title: String
}
