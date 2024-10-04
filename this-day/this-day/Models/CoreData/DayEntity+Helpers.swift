//
//  DayEntity+Helpers.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension DayEntity {
    static func createID(date: Date, language: String) -> String {
        return "\(language)-\(date.toFormat("dd-MM"))"
    }

    @discardableResult
    static func from(model: DayNetworkModel, id: String, date: Date,
                     language: String, context: NSManagedObjectContext) -> DayEntity {
        let dayEntity = DayEntity(context: context)
        dayEntity.id = id
        dayEntity.language = language
        dayEntity.text = model.text
        dayEntity.date = Date()

        let eventTypes: [(events: [EventNetworkModel], type: EventType)] = [
            (model.general, .general),
            (model.births, .birth),
            (model.deaths, .death)
        ]

        for (events, type) in eventTypes {
            for eventNetworkModel in events {
                let eventEntity = EventEntity.from(
                    model: eventNetworkModel, dayID: dayEntity.id, type: type, context: context)
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
