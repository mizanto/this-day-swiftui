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
