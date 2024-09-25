//
//  StorageServiceMock.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import Foundation
import CoreData

@testable import this_day

final class StorageServiceMock: StorageServiceProtocol {
    var context: NSManagedObjectContext
    var days: [String: DayEntity] = [:]
    var events: [UUID: EventEntity] = [:]
    var bookmarkedEvents: [UUID: EventEntity] = [:]

    var fetchDayCalled = false
    var saveDayCalled = false
    var fetchEventCalled = false
    var addToBookmarksCalled = false
    var removeFromBookmarksCalled = false
    var fetchBookmarksCalled = false

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchDay(for id: String) throws -> DayEntity? {
        fetchDayCalled = true
        return days[id]
    }

    func saveDay(networkModel: DayNetworkModel, for date: Date) throws {
        saveDayCalled = true
        let idString = date.toFormat("MM_dd")

        let dayEntity = DayEntity.from(networkModel: networkModel, date: date, context: context)
        try context.save()
        days[idString] = dayEntity
        
        if let event = dayEntity.events?.firstObject as? EventEntity {
            events[event.id] = event
        }
    }

    func fetchEvent(for id: UUID) throws -> EventEntity? {
        fetchEventCalled = true
        return events[id]
    }

    func addToBookmarks(event: EventEntity) throws {
        addToBookmarksCalled = true
        event.inBookmarks = true
        bookmarkedEvents[event.id] = event
        
        try context.save()
    }

    func removeFromBookmarks(event: EventEntity) throws {
        removeFromBookmarksCalled = true
        event.inBookmarks = false
        bookmarkedEvents.removeValue(forKey: event.id)
        
        try context.save()
    }

    func fetchBookmarks() throws -> [EventEntity] {
        fetchBookmarksCalled = true
        return Array(bookmarkedEvents.values)
    }
}
