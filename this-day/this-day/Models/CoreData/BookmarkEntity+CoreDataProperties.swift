//
//  BookmarkEntity+CoreDataProperties.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//
//

import Foundation
import CoreData

extension BookmarkEntity {

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<BookmarkEntity> {
        return NSFetchRequest<BookmarkEntity>(entityName: "BookmarkEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var dateAdded: Date
    @NSManaged public var event: EventEntity?

}

extension BookmarkEntity: Identifiable {}
