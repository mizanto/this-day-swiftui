//
//  HistoryService.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation
import Combine

protocol HistoryServiceProtocol {
    func fetchEvents(for date: Date) -> AnyPublisher<[EventNetworkModel], NetworkServiceError>
}

final class HistoryService: BaseNetworkService, HistoryServiceProtocol {
    private let baseURL = "https://history.muffinlabs.com"

    func fetchEvents(for date: Date) -> AnyPublisher<[EventNetworkModel], NetworkServiceError> {
        guard let month = date.month, let day = date.day else {
            AppLogger.shared.error("Invalid date components for fetching history", category: .network)
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        guard let url = URL(string: "\(baseURL)/date/\(month)/\(day)") else {
            AppLogger.shared.error("Invalid URL for date: \(date)", category: .network)
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }
        
        AppLogger.shared.info("Fetching history for date: \(date) with URL: \(url)", category: .network)
        
        return fetchData(from: url)
            .map { (response: EventsNetworkModel) in
                return response.events
            }
            .eraseToAnyPublisher()
    }
}
