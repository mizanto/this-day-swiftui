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

//final class EventsViewModelTests: XCTestCase {
//    private var viewModel: EventsViewModel!
//    private var historyServiceMock: HistoryServiceMock!
//    private var routerMock: EventsRouterMock!
//    private var cancellables: Set<AnyCancellable>!
//
//    override func setUp() {
//        super.setUp()
//        historyServiceMock = HistoryServiceMock()
//        routerMock = EventsRouterMock()
//        viewModel = EventsViewModel(networkService: historyServiceMock, router: routerMock)
//        cancellables = []
//    }
//
//    override func tearDown() {
//        viewModel = nil
//        historyServiceMock = nil
//        routerMock = nil
//        cancellables = nil
//        super.tearDown()
//    }
//
//    func testFetchEventsSuccess() {
//        let networkModel = EventNetworkModel(
//            year: "1",
//            text: "Test text",
//            links: [
//                EventLinkNetworkModel(title: "Test title", link: "https://wikipedia.org")
//            ]
//        )
//        let mockEvents = [networkModel]
//        historyServiceMock.events = mockEvents
//
//        let expectation = XCTestExpectation(description: "Fetch events successfully")
//
//        viewModel.$state
//            .dropFirst()  // Drop the initial loading state
//            .sink { state in
//                if case .loaded(let events) = state {
//                    XCTAssertEqual(events.count, mockEvents.count)
//                    XCTAssertEqual(events.first?.year, networkModel.year)
//                    XCTAssertEqual(events.first?.text, networkModel.text)
//                    expectation.fulfill()
//                }
//            }
//            .store(in: &cancellables)
//
//        viewModel.fetchEvents(for: Date())
//
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    func testFetchEventsNetworkError() {
//        historyServiceMock.error = .networkError(URLError(.notConnectedToInternet))
//
//        let expectation = XCTestExpectation(description: "Fetch events with network error")
//
//        viewModel.$state
//            .dropFirst()  // Drop the initial loading state
//            .sink { state in
//                if case .error(let message) = state {
//                    XCTAssertEqual(message, "Failed to load events. Please try again.")
//                    expectation.fulfill()
//                }
//            }
//            .store(in: &cancellables)
//
//        viewModel.fetchEvents(for: Date())
//        wait(for: [expectation], timeout: 1.0)
//    }
//
//    func testViewForEvent() {
//        let routerMock = EventsRouterMock()
//        let viewModel = EventsViewModel(networkService: HistoryServiceMock(), router: routerMock)
//
//        let mockEvent = Event(year: "1",
//                              text: "Test text",
//                              links: [])
//
//        _ = viewModel.view(for: mockEvent)
//
//        XCTAssertTrue(routerMock.didCallViewForEvent, "The router's view(for:) method should be called")
//    }
//}
