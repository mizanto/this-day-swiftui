//
//  DayDataModel.swift
//  this-day
//
//  Created by Sergey Bendak on 4.10.2024.
//

import Foundation

struct DayDataModel {
    let id: String
    let date: Date
    let text: String
    let language: String
    let general: [EventDataModel]
    let births: [EventDataModel]
    let deaths: [EventDataModel]

    init(entity: DayEntity) {
        self.id = entity.id
        self.date = entity.date
        self.text = entity.text
        self.language = entity.language

        var events: [EventType: [EventDataModel]] = [.general: [], .birth: [], .death: []]
        entity.eventsArray.forEach {
            events[EventType(rawValue: $0.type) ?? .general]?.append(EventDataModel(entity: $0))
        }
        general = events[.general] ?? []
        births = events[.birth] ?? []
        deaths = events[.death] ?? []
    }
}
