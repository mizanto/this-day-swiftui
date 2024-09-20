//
//  DayNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import Foundation

struct DayNetworkModel: Codable {
    let text: String
    let events: [EventNetworkModel]
    let births: [EventNetworkModel]
    let deaths: [EventNetworkModel]
    let holidays: [EventNetworkModel]
}
