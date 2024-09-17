//
//  URLSessionMock.swift
//  this-day-tests
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

@testable import this_day

final class URLSessionMock: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: URLError?

    func performRequestPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        // Create a Future publisher to simulate asynchronous behavior
        return Future<(data: Data, response: URLResponse), URLError> { promise in
            // Simulate network delay if needed using DispatchQueue
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {  // Simulating delay
                if let error = self.error {
                    promise(.failure(error))  // Return mock error if present
                } else if let data = self.data, let response = self.response {
                    promise(.success((data: data, response: response)))  // Return mock data and response if no error
                } else {
                    // If both data and error are nil, return a generic error
                    promise(.failure(URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: "Mock data or response is missing."])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
