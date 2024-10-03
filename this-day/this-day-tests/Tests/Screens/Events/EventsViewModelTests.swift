//
//  EventsViewModelTests.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import XCTest
import Combine
import SwiftUI

@testable import this_day

final class DayViewModelTests: XCTestCase {
    private var viewModel: DayViewModel!
    private var networkServiceMock: NetworkServiceMock!
    private var storageServiceMock: StorageServiceMock!
    private var localizationManagerMock: LocalizationManagerMock!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkServiceMock = NetworkServiceMock()
        _ = PersistenceController(inMemory: true)
        storageServiceMock = StorageServiceMock(context: PersistenceController.shared.container.viewContext)
        localizationManagerMock = LocalizationManagerMock()
        viewModel = DayViewModel(networkService: networkServiceMock, storageService: storageServiceMock, localizationManager: localizationManagerMock)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        networkServiceMock = nil
        storageServiceMock = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.state, .initial)
        XCTAssertEqual(viewModel.snackbarMessage, "Copied to clipboard")
        XCTAssertFalse(viewModel.showSnackbar)
        XCTAssertEqual(viewModel.selectedCategory, .events)
    }
    
    func testOnAppearWithoutCacheSuccess() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        let expectation = XCTestExpectation(description: "Fetch day successfully")
        
        viewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                if case .data(let events) = state {
                    XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                    XCTAssertTrue(storageServiceMock.saveDayCalled, "Save day not called")
                    XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                    XCTAssertTrue(networkServiceMock.fetchEventsCalled, "Fetch events not called")
                    XCTAssertEqual(events.count, 1, "Invalid events count")
                } else if case .error(let errorMessage) = state {
                    XCTFail("Test failed with error state: \(errorMessage)")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testOnAppearWithCacheSuccess() {
        let networkModel = setupMockDay(category: .events)
        
        do {
            try storageServiceMock.saveDay(networkModel: networkModel, for: Date())
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
        
        storageServiceMock.saveDayCalled = false
        
        let expectation = XCTestExpectation(description: "Fetch day successfully")
        
        viewModel.$state
            .dropFirst()
            .sink { [weak self] state in
                print("State: \(state)")
                guard let self else { return }
                if case .data(let events) = state {
                    XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                    XCTAssertFalse(storageServiceMock.saveDayCalled, "Save day called")
                    XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                    XCTAssertFalse(networkServiceMock.fetchEventsCalled, "Fetch events called")
                    XCTAssertEqual(events.count, 1, "Invalid events count")
                    XCTAssertEqual(viewModel.title, self.currentDateFormatted(), "Invalid title")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testOnAppearFetchDataFailure() {
        networkServiceMock.error = .networkError(URLError(.badServerResponse))
        
        let expectation = XCTestExpectation(description: "Failed to load events. Please try again.")
        
        viewModel.$state
            .sink(
                receiveCompletion: { completion in
                    XCTFail("Completion should not be received.")
                    expectation.fulfill()
                }, receiveValue: { state in
                    if case .error(let message) = state {
                        XCTAssertEqual(message, "Failed to load events. Please try again.")
                        expectation.fulfill()
                    }
                }
            )
            .store(in: &cancellables)
        
        viewModel.onAppear()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testOnTryAgainFetchDataSuccess() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        let expectation = XCTestExpectation(description: "Refetch day successfully")
        
        viewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                if case .data(let events) = state {
                    XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                    XCTAssertTrue(storageServiceMock.saveDayCalled, "Save day not called")
                    XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                    XCTAssertTrue(networkServiceMock.fetchEventsCalled, "Fetch events not called")
                    XCTAssertEqual(events.count, 1, "Invalid events count")
                    XCTAssertEqual(viewModel.title, self.currentDateFormatted(), "Invalid title")
                } else if case .error(let errorMessage) = state {
                    XCTFail("Test failed with error state: \(errorMessage)")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testOnTryAgainFetchDataFailure() {
        networkServiceMock.error = .networkError(URLError(.badServerResponse))
        
        let expectation = XCTestExpectation(description: "Refetch events with network error")
        
        viewModel.$state
            .sink { state in
                if case .error(let message) = state {
                    XCTAssertEqual(message, "Failed to load events. Please try again.")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testEventsSelection() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        performOnAppearAndWait()
        
        viewModel.selectedCategory = .births
        
        let expectation = XCTestExpectation(description: "Selected category should change to events")
        
        viewModel.$state
            .sink { state in
                if case .data(let events) = state {
                    guard !events.isEmpty else { return }
                    
                    XCTAssertEqual(events.count, 1)
                    let event = events.first as? Event
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.year, day.general.first?.year)
                    XCTAssertEqual(event!.title, day.general.first?.title)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.selectedCategory = .events
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBirthsSelection() {
        let day = setupMockDay(category: .births)
        networkServiceMock.day = day
        
        performOnAppearAndWait()
        
        let expectation = XCTestExpectation(description: "Selected category should change to births")
        
        viewModel.selectedCategory = .births
        
        viewModel.$state
            .sink { state in
                if case .data(let events) = state {
                    guard !events.isEmpty else { return }
                    
                    XCTAssertEqual(events.count, 1)
                    let event = events.first as? Event
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.year, day.births.first?.year)
                    XCTAssertEqual(event!.title, day.births.first?.title)
                    XCTAssertEqual(event!.subtitle, day.births.first?.additional)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDeathsSelection() {
        let day = setupMockDay(category: .deaths)
        networkServiceMock.day = day
        
        performOnAppearAndWait()
        
        let expectation = XCTestExpectation(description: "Selected category should change to deaths")
        
        viewModel.$state
            .sink { state in
                if case .data(let events) = state {
                    guard !events.isEmpty else { return }
                    
                    XCTAssertEqual(events.count, 1)
                    let event = events.first as? Event
                    XCTAssertNotNil(event)
                    XCTAssertEqual(event!.year, day.deaths.first?.year)
                    XCTAssertEqual(event!.title, day.deaths.first?.title)
                    XCTAssertEqual(event!.subtitle, day.deaths.first?.additional)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.selectedCategory = .deaths
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAddEventToBookmarks() {
        let dayNetworkModel = setupMockDay(category: .events)
        let date = Date()
        try? storageServiceMock.saveDay(networkModel: dayNetworkModel, for: date)
        guard let event = storageServiceMock.events.first?.value else {
            XCTFail("No event in storage")
            return
        }
        
        viewModel.toggleBookmark(for: event.id)
        
        XCTAssertTrue(storageServiceMock.events.first!.value.inBookmarks)
        XCTAssertTrue(storageServiceMock.addToBookmarksCalled)
        XCTAssertFalse(storageServiceMock.removeFromBookmarksCalled)
    }
    
    func testRemoveEventFromBookmarks() {
        let dayNetworkModel = setupMockDay(category: .events)
        let date = Date()
        try? storageServiceMock.saveDay(networkModel: dayNetworkModel, for: date)
        guard let event = storageServiceMock.events.first?.value else {
            XCTFail("No event in storage")
            return
        }
        // add to bookmarks
        viewModel.toggleBookmark(for: event.id)
        storageServiceMock.addToBookmarksCalled = false
        
        // remove from bookmarks
        viewModel.toggleBookmark(for: event.id)
        
        XCTAssertFalse(storageServiceMock.events.first!.value.inBookmarks)
        XCTAssertTrue(storageServiceMock.removeFromBookmarksCalled)
        XCTAssertFalse(storageServiceMock.addToBookmarksCalled)
    }
    
    func testCopyEventToClipboard() {
        let dayNetworkModel = setupMockDay(category: .events)
        let date = Date()
        try? storageServiceMock.saveDay(networkModel: dayNetworkModel, for: date)
        viewModel.onAppear()
        
        performOnAppearAndWait()
        
        if let event = storageServiceMock.events.first?.value {
            viewModel.copyToClipboardEvent(id: event.id)
            
            XCTAssertTrue(viewModel.showSnackbar)
            XCTAssertEqual(viewModel.snackbarMessage, "Copied to clipboard")
        } else {
            XCTFail("No event in storage")
        }
    }

    // MARK: - Helper Methods
    
    private func performOnAppearAndWait() {
        let onAppearExpectation = XCTestExpectation(description: "onAppear should complete")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .data = state {
                    onAppearExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.onAppear()
        
        wait(for: [onAppearExpectation], timeout: 2.0)
    }
    
    private func setupMockDay(category: EventCategory) -> DayNetworkModel {
        let text = "Test text"
        
        switch category {
        case .events:
            return DayNetworkModel(
                text: text, general: [EventNetworkModel(year: "1111", title: "Title")], births: [], deaths: []
            )
        case .births:
            return DayNetworkModel(
                text: text, general: [], births: [EventNetworkModel(year: "1111", title: "Title", additional: "Additional")], deaths: []
            )
        case .deaths:
            return DayNetworkModel(
                text: text, general: [], births: [], deaths: [EventNetworkModel(year: "1111", title: "Title", additional: "Additional")]
            )
        }
    }
    
    private func currentDateFormatted() -> String {
        return Date().toFormat("MMMM dd")
    }
}
