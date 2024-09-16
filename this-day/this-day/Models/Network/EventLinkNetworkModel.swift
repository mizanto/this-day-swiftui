//
//  EventLinkNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventLinkNetworkModel: Codable {
    let title: String
    let link: String
}

extension EventLinkNetworkModel {
    func toUIModel() -> EventLink {
        return EventLink(title: self.title, link: self.link)
    }
}
