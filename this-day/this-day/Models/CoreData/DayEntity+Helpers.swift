//
//  DayEntity+Helpers.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension DayEntity {
    static func createID(date: Date, language: String) -> String {
        return date.toFormat("ddMM") + language.uppercased()
    }

    static func from(networkModel: DayNetworkModel,
                     date: Date,
                     language: String,
                     context: NSManagedObjectContext) -> DayEntity {
        let dayEntity = DayEntity(context: context)
        dayEntity.id = createID(date: date, language: language)
        dayEntity.language = language
        dayEntity.text = networkModel.text
        dayEntity.date = Date()

        let eventTypes: [(events: [EventNetworkModel], type: EventType)] = [
            (networkModel.general, .general),
            (networkModel.births, .birth),
            (networkModel.deaths, .death),
        ]

        for (events, type) in eventTypes {
            for eventNetworkModel in events {
                let eventEntity = EventEntity.from(networkModel: eventNetworkModel, type: type, context: context)
                eventEntity.day = dayEntity
                dayEntity.addToEvents(eventEntity)
            }
        }
        return dayEntity
    }

    var eventsArray: [EventEntity] {
        let orderedSet = events ?? NSOrderedSet()
        return orderedSet.array as? [EventEntity] ?? []
    }
}
