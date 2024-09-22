//
//  EventNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventNetworkModel: Codable {
    let title: String
    let text: String?
    let additional: String?

    init(title: String, text: String? = nil, additional: String? = nil) {
        self.title = title
        self.text = text
        self.additional = additional
    }
}
