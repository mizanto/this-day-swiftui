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
        sessionMock.data = fakeDayData
        sessionMock.response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)!
        sessionMock.error = nil

        let expectation = XCTestExpectation(description: "Fetch day data successfully")

        networkService.fetchEvents(for: Date())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got failure with error: \(error)")
                }
            }, receiveValue: { day in
                XCTAssertTrue(day.text.isEmpty)
                XCTAssertEqual(day.general.count, 0)
                XCTAssertEqual(day.births.count, 0)
                XCTAssertEqual(day.deaths.count, 0)
                XCTAssertEqual(day.holidays.count, 0)
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
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
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
    var fakeDayData: Data {
                """
                {
                  "batchcomplete": "",
                  "query": {
                    "normalized": [
                      {
                        "from": "September_20",
                        "to": "September 20"
                      }
                    ],
                    "pages": {
                      "28148": {
                        "pageid": 28148,
                        "ns": 0,
                        "title": "September 20",
                        "extract": "=="
                      }
                    }
                  }
                }
                """.data(using: .unicode)!
    }
}
