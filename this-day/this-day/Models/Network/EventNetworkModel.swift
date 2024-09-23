//
//  EventNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventNetworkModel: Codable {
    let year: String?
    let title: String?
    let additional: String?

    init(year: String? = nil, title: String? = nil, additional: String? = nil) {
        self.year = year
        self.title = title
        self.additional = additional
    }
}
