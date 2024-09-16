//
//  HistoryNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventsNetworkModel: Codable {
    let date: String
    let url: String
    let events: [EventNetworkModel]

    enum CodingKeys: String, CodingKey {
        case date
        case url
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case events = "Events"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        url = try container.decode(String.self, forKey: .url)

        let dataContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        events = try dataContainer.decode([EventNetworkModel].self, forKey: .events)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(url, forKey: .url)

        var dataContainer = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        try dataContainer.encode(events, forKey: .events)
    }
}

extension EventsNetworkModel {
    func toUIModel() -> HistoryEvents {
        HistoryEvents(date: date,
                      events: events.map { $0.toUIModel() })
    }
}
