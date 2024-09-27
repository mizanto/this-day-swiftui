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
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkServiceMock = NetworkServiceMock()
        _ = PersistenceController(inMemory: true)
        storageServiceMock = StorageServiceMock(context: PersistenceController.shared.container.viewContext)
        viewModel = DayViewModel(networkService: networkServiceMock, storageService: storageServiceMock)
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
        XCTAssertEqual(viewModel.selectedCategory, .events)
    }
    
    func testOnAppearWithoutCacheSuccess() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        assertViewModelValidState(
            expectationDescription: "Fetch day successfully",
            stateChangeAction: { [weak self] in
                self?.viewModel.onAppear()
            },
            asserts: { [weak self] events in
                guard let self else {
                    XCTFail("self is nil")
                    return
                }
                guard let events = events as? [ExtendedEvent] else {
                    XCTFail("Invalid events type")
                    return
                }
                XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                XCTAssertTrue(storageServiceMock.saveDayCalled, "Save day not called")
                XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                XCTAssertTrue(networkServiceMock.fetchEventsCalled, "Fetch events not called")
                XCTAssertEqual(events.count, 1, "Invalid events count")
                XCTAssertEqual(events.first?.year, day.general.first?.year, "Invalid year")
                XCTAssertEqual(events.first?.title, day.general.first?.title, "Invalid title")
                XCTAssertEqual(self.viewModel.title, self.currentDateFormatted(), "Invalid title")
            }
        )
    }
    
    func testOnAppearWithCacheSuccess() {
        let networkModel = setupMockDay(category: .events)
        try? storageServiceMock.saveDay(networkModel: networkModel, for: Date())
        storageServiceMock.saveDayCalled = false
        
        assertViewModelValidState(
            expectationDescription: "Fetch day successfully",
            stateChangeAction: { [weak self] in
                self?.viewModel.onAppear()
            },
            asserts: { [weak self] events in
                guard let self else {
                    XCTFail("self is nil")
                    return
                }
                guard let events = events as? [ExtendedEvent] else {
                    XCTFail("Invalid events type")
                    return
                }
                XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                XCTAssertFalse(storageServiceMock.saveDayCalled, "Save day called")
                XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                XCTAssertFalse(networkServiceMock.fetchEventsCalled, "Fetch events called")
                XCTAssertEqual(events.count, 1, "Invalid events count")
                XCTAssertEqual(events.first?.year, networkModel.general.first?.year, "Invalid year")
                XCTAssertEqual(events.first?.title, networkModel.general.first?.title, "Invalid title")
                XCTAssertEqual(self.viewModel.title, self.currentDateFormatted(), "Invalid title")
            }
        )
    }
    
    func testOnAppearFetchDataFailure() {
        networkServiceMock.error = .networkError(URLError(.badServerResponse))
        
        assertViewModelErrorState(
            expectationDescription: "Fetch events with network error",
            stateChangeAction: { [weak self] in
                self?.viewModel.onAppear()
            }
        )
    }
    
    func testOnTryAgainFetchDataSuccess() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        
        assertViewModelValidState(
            expectationDescription: "Refetch day successfully",
            stateChangeAction: { [weak self] in
                self?.viewModel.onTryAgain()
            },
            asserts: { [weak self] events in
                guard let self else {
                    XCTFail("self is nil")
                    return
                }
                guard let events = events as? [ExtendedEvent] else {
                    XCTFail("Invalid events type")
                    return
                }
                XCTAssertTrue(storageServiceMock.fetchDayCalled, "Fetch day not called")
                XCTAssertTrue(storageServiceMock.saveDayCalled, "Save day not called")
                XCTAssertEqual(storageServiceMock.days.count, 1, "Invalid days count")
                XCTAssertTrue(networkServiceMock.fetchEventsCalled, "Fetch events not called")
                XCTAssertEqual(events.count, 1, "Invalid events count")
                XCTAssertEqual(events.first!.year, day.general.first!.year, "Invalid year \(events.first!.year)")
                XCTAssertEqual(events.first!.title, day.general.first!.title, "Invalid title \(events.first!.title)")
            }
        )
    }
    
    func testOnTryAgainFetchDataFailure() {
        networkServiceMock.error = .networkError(URLError(.badServerResponse))
        
        assertViewModelErrorState(
            expectationDescription: "Refetch events with network error",
            stateChangeAction: { [weak self] in
                self?.viewModel.onTryAgain()
            }
        )
    }
    
    func testEventsSelection() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        viewModel.onAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.assertViewModelValidState(
                expectationDescription: "Selected category should change to events",
                stateChangeAction: { [weak self] in
                    self?.viewModel.selectedCategory = .events
                },
                asserts: { [weak self] events in
                    guard let events = events as? [ExtendedEvent] else {
                        XCTFail("Invalid events type")
                        return
                    }
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.year, day.general.first?.year)
                    XCTAssertEqual(events.first?.title, day.general.first?.title)
                    XCTAssertEqual(self?.viewModel.subtitle, day.text)
                }
            )
        }
    }
    
    func testBirthsSelection() {
        let day = setupMockDay(category: .births)
        networkServiceMock.day = day
        
        viewModel.onAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let strongSelf = self else {
                XCTFail("Test case deallocated unexpectedly")
                return
            }
            strongSelf.assertViewModelValidState(
                expectationDescription: "Selected category should change to events",
                stateChangeAction: {
                    strongSelf.viewModel.selectedCategory = .births
                },
                asserts: { events in
                    guard let events = events as? [ExtendedEvent] else {
                        XCTFail("Invalid events type")
                        return
                    }
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.year, day.births.first?.year)
                    XCTAssertEqual(events.first?.title, day.births.first?.title)
                    XCTAssertEqual(events.first?.subtitle, day.births.first?.additional)
                    XCTAssertEqual(self?.viewModel.subtitle, day.text)
                }
            )
        }
    }
    
    func testDeathsSelection() {
        let day = setupMockDay(category: .deaths)
        networkServiceMock.day = day
        
        viewModel.onAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.assertViewModelValidState(
                expectationDescription: "Selected category should change to events",
                stateChangeAction: { [weak self] in
                    self?.viewModel.selectedCategory = .deaths
                },
                asserts: { [weak self] events in
                    guard let events = events as? [ExtendedEvent] else {
                        XCTFail("Invalid events type")
                        return
                    }
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.year, day.deaths.first?.year)
                    XCTAssertEqual(events.first?.title, day.deaths.first?.title)
                    XCTAssertEqual(events.first?.subtitle, day.deaths.first?.additional)
                    XCTAssertEqual(self?.viewModel.subtitle, day.text)
                }
            )
        }
    }
    
    func testHolidaysSelection() {
        let day = setupMockDay(category: .holidays)
        networkServiceMock.day = day
        
        viewModel.onAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.assertViewModelValidState(
                expectationDescription: "Selected category should change to events",
                stateChangeAction: { [weak self] in
                    self?.viewModel.selectedCategory = .holidays
                },
                asserts: { [weak self] events in
                    guard let events = events as? [ShortEvent] else {
                        XCTFail("Invalid events type")
                        return
                    }
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.title, day.deaths.first?.title)
                    XCTAssertEqual(self?.viewModel.subtitle, day.text)
                }
            )
        }
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

    // MARK: - Helper Methods
    
    private func setupMockDay(category: EventCategory) -> DayNetworkModel {
        let text = "Test text"
        
        switch category {
        case .events:
            return DayNetworkModel(
                text: text, general: [EventNetworkModel(year: "1111", title: "Title")], births: [], deaths: [], holidays: []
            )
        case .births, .deaths:
            return DayNetworkModel(
                text: text, general: [], births: [EventNetworkModel(year: "1111", title: "Title", additional: "Additional")], deaths: [], holidays: []
            )
        case .holidays:
            return DayNetworkModel(
                text: text, general: [], births: [], deaths: [], holidays: [EventNetworkModel(title: "Title")]
            )
        }
    }
    
    private func assertViewModelValidState(expectationDescription: String,
                                           stateChangeAction: @escaping () -> Void,
                                           asserts: @escaping ([any EventProtocol]) -> Void) {
        let expectation = XCTestExpectation(description: expectationDescription)

        print("Starting assertion for: \(expectationDescription)")
        
        viewModel.$state
            .dropFirst() // Drop the initial loading state
            .sink { state in
                print("Received state update: \(state)")
                if case .data(let events) = state {
                    print("State is .data with events count: \(events.count)")
                    asserts(events)
                    expectation.fulfill()
                } else if case .error(let errorMessage) = state {
                    XCTFail("Test failed with error state: \(errorMessage)")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        stateChangeAction()
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func assertViewModelErrorState(expectationDescription: String,
                                           stateChangeAction: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$state
            .dropFirst() // Drop the initial loading state
            .sink { state in
                if case .error(let message) = state {
                    XCTAssertEqual(message, "Failed to load events. Please try again.")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        stateChangeAction()
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func currentDateFormatted() -> String {
        return Date().toFormat("MMMM dd")
    }
}
