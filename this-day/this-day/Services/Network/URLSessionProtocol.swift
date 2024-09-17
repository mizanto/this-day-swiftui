//
//  URLSessionProtocol.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

protocol URLSessionProtocol {
    // Renamed method to avoid ambiguity with URLSession's dataTaskPublisher(for:)
    func performRequestPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// Extend URLSession to conform to URLSessionProtocol using Combine's dataTaskPublisher(for:)
extension URLSession: URLSessionProtocol {
    // Implement the renamed method to return the original dataTaskPublisher
    func performRequestPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        self.dataTaskPublisher(for: url)
            .map { ($0.data, $0.response) }  // Map to match protocol return type
            .eraseToAnyPublisher()  // Erase type to AnyPublisher for flexibility
    }
}
