//
//  EventEntity+CoreDataProperties.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//
//

import Foundation
import CoreData

extension EventEntity {

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<EventEntity> {
        return NSFetchRequest<EventEntity>(entityName: "EventEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var subtitle: String?
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var year: String
    @NSManaged public var day: DayEntity?
    @NSManaged public var bookmark: BookmarkEntity?
}

extension EventEntity: Identifiable {}
