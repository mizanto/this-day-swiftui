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

    static func extractDateAndLanguage(from dayID: String) -> (date: Date, language: String)? {
        let components = dayID.split(separator: "-")
        
        guard components.count == 3 else {
            AppLogger.shared.error("Invalid dayID format: \(dayID)", category: .database)
            return nil
        }
        
        let language = String(components[0])
        let day = String(components[1])
        let month = String(components[2])
        let year = String(Calendar.current.component(.year, from: Date()))
        
        let dateString = "\(day)-\(month)-\(year)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = Locale(identifier: language)
        
        guard let date = formatter.date(from: dateString) else { return nil }
        
        return (date, language)
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
