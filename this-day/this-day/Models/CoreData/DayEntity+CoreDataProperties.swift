//
//  DayEntity+CoreDataProperties.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//
//

import Foundation
import CoreData


extension DayEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DayEntity> {
        return NSFetchRequest<DayEntity>(entityName: "DayEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var added: Date?
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for events
extension DayEntity {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: EventEntity)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: EventEntity)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}

extension DayEntity : Identifiable {}

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
}
