//
//  EventNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventNetworkModel: Codable {
    let year: String
    let title: String
    let additional: String? // nil for general

    init(year: String, title: String, additional: String? = nil) {
        self.year = year
        self.title = title
        self.additional = additional
    }
}
