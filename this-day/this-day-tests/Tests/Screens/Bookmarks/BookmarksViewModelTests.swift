//
//  BookmarksViewModelTests.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import XCTest
import Combine
import CoreData

@testable import this_day

final class BookmarksViewModelTests: XCTestCase {
    private var viewModel: BookmarksViewModel!
    private var context: NSManagedObjectContext!
    private var storageServiceMock: StorageServiceMock!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        _ = PersistenceController(inMemory: true)
        context = PersistenceController.shared.container.viewContext
        storageServiceMock = StorageServiceMock(context: context)
        viewModel = BookmarksViewModel(storageService: storageServiceMock)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        storageServiceMock = nil
        context = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.state, .initial)
        XCTAssertNil(viewModel.itemsForSahre)
    }
    
    func testOnAppearWithEmptyBookmarks() {
        let expectation = XCTestExpectation(description: "Bookmarks should be empty")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .data(let bookmarks) = state {
                    XCTAssertTrue(bookmarks.isEmpty)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        
        XCTAssertNoThrow(wait(for: [expectation], timeout: 1))
    }
    
    func testOnAppearWithBookmarks() {
        let event = createAndSaveEvent(title: "Test Event", type: .general)
        try? storageServiceMock.addToBookmarks(event: event)
        
        let expectation = XCTestExpectation(description: "Bookmarks should not be empty")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .data(let bookmarks) = state {
                    XCTAssertFalse(bookmarks.isEmpty)
                    XCTAssertEqual(bookmarks.count, 1)
                    XCTAssertEqual(bookmarks.first?.title, event.title)
                    XCTAssertEqual(bookmarks.first?.category, EventCategory.from(event.eventType))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        
        XCTAssertNoThrow(wait(for: [expectation], timeout: 1))
    }
    
    func testOnAppearWithError() {
        let error = StorageServiceError.unknownError("Test error")
        storageServiceMock.error = error
        
        let expectation = XCTestExpectation(description: "Error should be shown")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .error(let message) = state {
                    XCTAssertEqual(message, "Failed to fetch bookmarks")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        
        XCTAssertNoThrow(wait(for: [expectation], timeout: 1))
    }
    
    func testRemoveBookmark() {
        let event = createAndSaveEvent(title: "Test Event", type: .general)
        try? storageServiceMock.addToBookmarks(event: event)
        viewModel.onAppear()
        
        let expectation = XCTestExpectation(description: "Bookmark should be removed")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .data(let bookmarks) = state {
                    XCTAssertTrue(bookmarks.isEmpty)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        if let id = event.bookmark?.id {
            viewModel.removeBookmark(for: id)
        }
        
        XCTAssertNoThrow(wait(for: [expectation], timeout: 1))
    }
    
    private func createAndSaveEvent(title: String, type: EventType) -> EventEntity {
        let event = EventEntity(context: context)
        event.id = UUID()
        event.title = title
        event.eventType = type
        try? context.save()
        return event
    }
}
