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
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkServiceMock = NetworkServiceMock()
        viewModel = DayViewModel(networkService: networkServiceMock)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        networkServiceMock = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.subtitle, "")
        XCTAssertEqual(viewModel.state, .loading)
        XCTAssertEqual(viewModel.selectedCategory, .events)
    }
    
    func testOnAppearFetchDataSuccess() {
        let day = setupMockDay(category: .events)
        networkServiceMock.day = day
        
        assertViewModelValidState(
            expectationDescription: "Fetch day successfully",
            stateChangeAction: { [weak self] in
                self?.viewModel.onAppear()
            },
            asserts: { [weak self] events in
                guard let self else { return }
                XCTAssertEqual(events.count, 1)
                XCTAssertEqual(events.first?.title, day.events.first?.title)
                XCTAssertEqual(events.first?.text, day.events.first?.text)
                XCTAssertEqual(self.viewModel.subtitle, day.text)
                XCTAssertEqual(self.viewModel.title, self.currentDateFormatted())
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
                guard let self else { return }
                XCTAssertEqual(events.count, 1)
                XCTAssertEqual(events.first?.title, day.events.first?.title)
                XCTAssertEqual(events.first?.text, day.events.first?.text)
                XCTAssertEqual(self.viewModel.subtitle, day.text)
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

    func testCategorySelection() {
        verifyCategorySelection(category: .events)
        verifyCategorySelection(category: .births)
        verifyCategorySelection(category: .deaths)
        verifyCategorySelection(category: .holidays)
    }

    // MARK: - Helper Methods
    
    private func setupMockDay(category: EventCategory) -> DayNetworkModel {
        let text = "Test text"
        let event = EventNetworkModel(title: "Test title", text: "Test text")
        
        return DayNetworkModel(
            text: text,
            events: category == .events ? [event] : [],
            births: category == .births ? [event] : [],
            deaths: category == .deaths ? [event] : [],
            holidays: category == .holidays ? [event] : []
        )
    }

    private func verifyCategorySelection(category: EventCategory) {
        let day = setupMockDay(category: category)
        networkServiceMock.day = day
        
        let eventsToCheck: [EventNetworkModel]
        switch category {
        case .events: eventsToCheck = day.events
        case .births: eventsToCheck = day.births
        case .deaths: eventsToCheck = day.deaths
        case .holidays: eventsToCheck = day.holidays
        }
        
        viewModel.onAppear()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.assertViewModelValidState(
                expectationDescription: "Selected category should change to \(category.rawValue)",
                stateChangeAction: { [weak self] in
                    self?.viewModel.selectedCategory = category
                },
                asserts: { [weak self] events in
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.title, eventsToCheck.first?.title)
                    XCTAssertEqual(events.first?.text, eventsToCheck.first?.text)
                    XCTAssertEqual(self?.viewModel.subtitle, day.text)
                }
            )
        }
    }
    
    private func assertViewModelValidState(expectationDescription: String,
                                           stateChangeAction: @escaping () -> Void,
                                           asserts: @escaping ([Event]) -> Void) {
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$state
            .dropFirst() // Drop the initial loading state
            .sink { state in
                if case .data(let events) = state {
                    asserts(events)
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
