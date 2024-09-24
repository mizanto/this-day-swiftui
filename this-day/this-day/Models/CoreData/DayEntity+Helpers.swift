//
//  DayEntity+Helpers.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import CoreData

extension DayEntity {
    static func from(networkModel: DayNetworkModel, date: Date, context: NSManagedObjectContext) -> DayEntity {
        let dayEntity = DayEntity(context: context)
        dayEntity.id = date.toFormat("MM_dd")
        dayEntity.text = networkModel.text
        dayEntity.added = Date()

        let eventTypes: [(events: [EventNetworkModel], type: EventType)] = [
            (networkModel.general, .general),
            (networkModel.births, .birth),
            (networkModel.deaths, .death),
            (networkModel.holidays, .holiday)
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
