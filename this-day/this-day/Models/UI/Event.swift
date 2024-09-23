//
//  Event.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct Event: Identifiable {
    let id = UUID()
    let year: String?
    let title: String?
    let subtitle: String?

    init(from networkModel: EventNetworkModel) {
        self.year = networkModel.year
        self.title = networkModel.title
        self.subtitle = networkModel.additional
    }
}
