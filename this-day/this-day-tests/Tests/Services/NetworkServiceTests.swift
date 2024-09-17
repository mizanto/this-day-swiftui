//
//  NetworkServiceTests.swift
//  this-day-tests
//
//  Created by Sergey Bendak on 17.09.2024.
//

import XCTest
import Combine

@testable import this_day

final class NetworkServiceTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    private var sessionMock: URLSessionMock!
    private var networkService: NetworkService!

    override func setUp() {
        super.setUp()
        cancellables = []
        sessionMock = URLSessionMock()
        networkService = NetworkService(session: sessionMock)
    }

    override func tearDown() {
        cancellables = nil
        sessionMock = nil
        networkService = nil
        super.tearDown()
    }

    func testFetchEventsSuccess() {
        sessionMock.data = fakeEventsData
        sessionMock.response = HTTPURLResponse(url: URL(string: "https://history.muffinlabs.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)!
        sessionMock.error = nil

        let expectation = XCTestExpectation(description: "Fetch events successfully")

        networkService.fetchEvents(for: Date())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got failure with error: \(error)")
                }
            }, receiveValue: { events in
                XCTAssertEqual(events.count, 1)
                XCTAssertEqual(events.first?.year, "681")
                XCTAssertEqual(events.first?.text, "Pope Honorius I is posthumously excommunicated by the Sixth Ecumenical Council.")
                XCTAssertEqual(events.first?.links.count, 2)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchEventsNetworkError() {
        sessionMock.data = nil
        sessionMock.response = nil
        sessionMock.error = URLError(.notConnectedToInternet)

        let expectation = XCTestExpectation(description: "Fetch events with network error")

        networkService.fetchEvents(for: Date())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    switch error {
                    case .networkError(let urlError as URLError):
                        XCTAssertEqual(urlError.code, .notConnectedToInternet)
                        expectation.fulfill()
                    default:
                        XCTFail("Expected network error but got \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure but got success")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchEventsDecodingError() {
        let invalidJSONData = "Invalid JSON".data(using: .utf8)
        let response = HTTPURLResponse(url: URL(string: "https://history.muffinlabs.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!

        sessionMock.data = invalidJSONData
        sessionMock.response = response
        sessionMock.error = nil

        let expectation = XCTestExpectation(description: "Fetch events with decoding error")

        networkService.fetchEvents(for: Date())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    switch error {
                    case .decodingError:
                        expectation.fulfill()
                    default:
                        XCTFail("Expected decoding error but got \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure but got success")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}

private extension NetworkServiceTests {
    var fakeEventsData: Data {
                """
                {
                    "date": "September 16",
                    "url": "https://wikipedia.org/wiki/September_16",
                    "data": {
                        "Events": [
                            {
                                "year": "681",
                                "text": "Pope Honorius I is posthumously excommunicated by the Sixth Ecumenical Council.",
                                "links": [
                                    {"title": "Pope Honorius I", "link": "https://wikipedia.org/wiki/Pope_Honorius_I"},
                                    {"title": "Excommunication", "link": "https://wikipedia.org/wiki/Excommunication"}
                                ]
                            }
                        ]
                    }
                }
                """.data(using: .utf8)!
    }
}
