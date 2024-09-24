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

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<DayEntity> {
        return NSFetchRequest<DayEntity>(entityName: "DayEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var added: Date?
    @NSManaged public var events: NSOrderedSet?

}

// MARK: Generated accessors for events
extension DayEntity {

    @objc(insertObject:inEventsAtIndex:)
    @NSManaged public func insertIntoEvents(_ value: EventEntity, at idx: Int)

    @objc(removeObjectFromEventsAtIndex:)
    @NSManaged public func removeFromEvents(at idx: Int)

    @objc(insertEvents:atIndexes:)
    @NSManaged public func insertIntoEvents(_ values: [EventEntity], at indexes: NSIndexSet)

    @objc(removeEventsAtIndexes:)
    @NSManaged public func removeFromEvents(at indexes: NSIndexSet)

    @objc(replaceObjectInEventsAtIndex:withObject:)
    @NSManaged public func replaceEvents(at idx: Int, with value: EventEntity)

    @objc(replaceEventsAtIndexes:withEvents:)
    @NSManaged public func replaceEvents(at indexes: NSIndexSet, with values: [EventEntity])

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: EventEntity)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: EventEntity)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSOrderedSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSOrderedSet)
}

extension DayEntity: Identifiable {}
