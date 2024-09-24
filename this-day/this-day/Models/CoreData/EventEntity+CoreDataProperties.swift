//
//  EventEntity+CoreDataProperties.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//
//

import Foundation
import CoreData


extension EventEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventEntity> {
        return NSFetchRequest<EventEntity>(entityName: "EventEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var year: String?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var type: String?
    @NSManaged public var day: DayEntity?

}

extension EventEntity : Identifiable {}

extension EventEntity {
    static func from(networkModel: EventNetworkModel, type: EventType, context: NSManagedObjectContext) -> EventEntity {
        let eventEntity = EventEntity(context: context)
        eventEntity.id = UUID()
        eventEntity.title = networkModel.title
        eventEntity.year = networkModel.year
        eventEntity.subtitle = networkModel.additional
        eventEntity.eventType = type
        return eventEntity
    }
}
