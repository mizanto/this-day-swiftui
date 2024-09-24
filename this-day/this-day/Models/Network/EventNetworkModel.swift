//
//  EventNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventNetworkModel: Codable {
    let year: String? // nil for hollidays
    let title: String
    let additional: String? // nil for general and hollidays

    init(year: String? = nil, title: String, additional: String? = nil) {
        self.year = year
        self.title = title
        self.additional = additional
    }
}
