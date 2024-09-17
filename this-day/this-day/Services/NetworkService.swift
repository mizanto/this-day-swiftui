//
//  NetworkService.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation
import Combine

enum NetworkServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

protocol NetworkServiceProtocol {
    func fetchEvents(for date: Date) -> AnyPublisher<[EventNetworkModel], NetworkServiceError>
}

final class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://history.muffinlabs.com"
    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    private func fetchData<T: Decodable>(from url: URL) -> AnyPublisher<T, NetworkServiceError> {
        AppLogger.shared.info("Fetching data from URL: \(url)", category: .network)

        // Use the renamed session method to perform the network request
        return session.performRequestPublisher(for: url)
            .handleEvents(receiveSubscription: { _ in
                AppLogger.shared.info("Started fetching data from \(url)", category: .network)
            }, receiveOutput: { _, response in
                if let httpResponse = response as? HTTPURLResponse {
                    AppLogger.shared.info("Received HTTP \(httpResponse.statusCode) from \(url)", category: .network)
                }
            }, receiveCompletion: { completion in
                switch completion {
                case .finished:
                    AppLogger.shared.info("Finished fetching data from \(url)", category: .network)
                case .failure(let error):
                    AppLogger.shared.error("Failed fetching data from \(url) with error: \(error)", category: .network)
                }
            })
            .mapError { error in
                AppLogger.shared.error("Network error occurred: \(error)", category: .network)
                return NetworkServiceError.networkError(error)
            }
            .flatMap { data, _ -> AnyPublisher<T, NetworkServiceError> in
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    AppLogger.shared.info("Successfully decoded data from \(url)", category: .network)
                    return Just(decodedData)
                        .setFailureType(to: NetworkServiceError.self)
                        .eraseToAnyPublisher()
                } catch {
                    AppLogger.shared.error("Decoding error for data from \(url): \(error)", category: .network)
                    return Fail(error: NetworkServiceError.decodingError(error))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

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
