//
//  StorageServiceTests.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import XCTest
import CoreData

@testable import this_day

final class StorageServiceTests: XCTestCase {
    var storageService: StorageService!
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        storageService = StorageService(context: context)
    }

    override func tearDownWithError() throws {
        context = nil
        storageService = nil
        try super.tearDownWithError()
    }
    
    func testFetchDaySuccess() throws {
        let id = "01_01"
        let dayEntity = DayEntity(context: context)
        dayEntity.id = id
        dayEntity.text = "Test text"
        dayEntity.date = Date()
        try context.save()

        let fetchedDay = try storageService.fetchDay(id: id)
        
        XCTAssertNotNil(fetchedDay)
        XCTAssertEqual(fetchedDay?.id, id)
    }

    func testFetchDayNotFound() throws {
        let fetchedDay = try storageService.fetchDay(id: "01_01")
        XCTAssertNil(fetchedDay)
    }
    
    func testSaveDaySuccess() throws {
        let networkModel = DayNetworkModel(
            text: "Test text",
            general: [EventNetworkModel(year: "2000", title: "Test title")],
            births: [],
            deaths: [],
            holidays: []
        )
        let date = Date(timeIntervalSince1970: 0) // 1 jan 1970
        
        try storageService.saveDay(networkModel: networkModel, for: date)
        
        let fetchedDay = try storageService.fetchDay(id: "01_01")
        
        XCTAssertNotNil(fetchedDay)
        XCTAssertEqual(fetchedDay?.id, "01_01")
        XCTAssertEqual(fetchedDay?.text, networkModel.text)
        XCTAssertEqual(fetchedDay?.events?.count, 1)
    }
    
    func testFetchEventSuccess() throws {
        let id = UUID()
        let title = "Test title"
        try createEvent(with: id, title: title, eventType: .general, in: context)

        let fetchedEvent = try storageService.fetchEvent(id: id)
        
        XCTAssertNotNil(fetchedEvent)
        XCTAssertEqual(fetchedEvent?.id, id)
        XCTAssertEqual(fetchedEvent?.eventType, .general)
        XCTAssertEqual(fetchedEvent?.title, title)
    }

    func testFetchEventNotFound() throws {
        let fetchedEvent = try storageService.fetchEvent(id: UUID())
        XCTAssertNil(fetchedEvent)
    }
    
    func testAddToBookmarksSuccess() throws {
        let eventEntity = try createEvent(
            with: UUID(), title: "Test title", eventType: .general, in: context)

        try storageService.addToBookmarks(event: eventEntity)
        
        XCTAssertNotNil(eventEntity.bookmark)
    }
    
    func testRemoveFromBookmarksSuccess() throws {
        let eventEntity = try createEvent(
            with: UUID(), title: "Test title", eventType: .general, inBookmarks: true, in: context)

        try storageService.removeFromBookmarks(event: eventEntity)
        
        XCTAssertNil(eventEntity.bookmark)
    }
    
    func testRemoveBookmarkSuccess() throws {
        let eventEntity = try createEvent(
            with: UUID(), title: "Test title", eventType: .general, inBookmarks: true, in: context)
        
        guard let bookmarkId = eventEntity.bookmark?.id else {
            XCTFail("Bookmark id is nil")
            return
        }

        try storageService.removeBookmark(id: bookmarkId)
        
        XCTAssertNil(eventEntity.bookmark)
    }
    
    func testFetchBookmarksSuccess() throws {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        try createEvent(with: id1, title: "Test title 1", eventType: .general, inBookmarks: true, in: context)
        try createEvent(with: id2, title: "Test title 2", eventType: .general, inBookmarks: false, in: context)
        try createEvent(with: id3, title: "Test title 3", eventType: .general, inBookmarks: true, in: context)

        let bookmarks = try storageService.fetchBookmarks()
        
        XCTAssertEqual(bookmarks.count, 2)
        XCTAssertTrue(bookmarks.contains(where: { $0.event?.id == id1 }))
        XCTAssertTrue(bookmarks.contains(where: { $0.event?.id == id3 }))
    }
    
    @discardableResult
    private func createEvent(with id: UUID,
                             title: String,
                             eventType: EventType,
                             inBookmarks: Bool = false,
                             in context: NSManagedObjectContext) throws -> EventEntity {
        let eventEntity = EventEntity(context: context)
        eventEntity.id = id
        eventEntity.title = title
        eventEntity.eventType = eventType
        if inBookmarks {
            try storageService.addToBookmarks(event: eventEntity)
        }
        try context.save()
        return eventEntity
    }
}
