//
//  EventNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventNetworkModel: Codable {
    let year: String
    let text: String
    let links: [EventLinkNetworkModel]
}

extension EventNetworkModel {
    func toUIModel() -> Event {
        return Event(
            year: self.year,
            text: self.text,
            links: self.links.map { $0.toUIModel() }
        )
    }
}
