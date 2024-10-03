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
    var bookmarks: [UUID: BookmarkEntity] = [:]
    var error: StorageError?

    var fetchDayCalled = false
    var saveDayCalled = false
    var fetchEventCalled = false
    var addToBookmarksCalled = false
    var removeFromBookmarksCalled = false
    var removeBookmarkCalled = false
    var fetchBookmarksCalled = false

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchDay(id: String) throws -> DayEntity? {
        try throwErrorIfNeeded()
        
        fetchDayCalled = true
        return days[id]
    }

    func saveDay(networkModel: DayNetworkModel, for date: Date, language: String = "en") throws {
        try throwErrorIfNeeded()
        
        saveDayCalled = true

        let day = DayEntity.from(networkModel: networkModel, date: date, language: language, context: context)
        try context.save()
        days[day.id] = day
        
        if let eventSet = day.events {
            for case let event as EventEntity in eventSet {
                events[event.id] = event
            }
        }
    }

    func fetchEvent(id: UUID) throws -> EventEntity? {
        try throwErrorIfNeeded()
        fetchEventCalled = true
        return events[id]
    }

    func addToBookmarks(event: EventEntity) throws {
        try throwErrorIfNeeded()
        
        addToBookmarksCalled = true
        
        let bookmark = BookmarkEntity.init(context: context)
        bookmark.id = UUID()
        bookmark.dateAdded = Date()
        bookmark.event = event
        try context.save()
        
        event.bookmark = bookmark
        bookmarks[bookmark.id] = bookmark
    }

    func removeFromBookmarks(event: EventEntity) throws {
        try throwErrorIfNeeded()
        
        removeFromBookmarksCalled = true
        
        if let id = event.bookmark?.id {
            event.bookmark = nil
            _ = bookmarks.removeValue(forKey: id)
            try context.save()
        } else {
            throw StorageError.notFound
        }
    }
    
    func removeBookmark(id: UUID) throws {
        try throwErrorIfNeeded()
        removeBookmarkCalled = true
        bookmarks.removeValue(forKey: id)
        try context.save()
    }
    
    func fetchBookmarks() throws -> [BookmarkEntity] {
        try throwErrorIfNeeded()
        fetchBookmarksCalled = true
        return Array(bookmarks.values)
    }
    
    private func throwErrorIfNeeded() throws {
        if let error = error {
            throw error
        }
    }
}
