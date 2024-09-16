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

class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://history.muffinlabs.com"

    private func fetchData<T: Decodable>(from url: URL) -> AnyPublisher<T, NetworkServiceError> {
        print("Fetching data from URL: \(url)")

        return URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents(receiveSubscription: { _ in
                print("Started fetching data from \(url)")
            }, receiveOutput: { _, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Received HTTP \(httpResponse.statusCode) from \(url)")
                }
            }, receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Finished fetching data from \(url)")
                case .failure(let error):
                    print("Failed fetching data from \(url) with error: \(error)")
                }
            })
            .mapError { NetworkServiceError.networkError($0) }
            .flatMap { data, _ -> AnyPublisher<T, NetworkServiceError> in
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    print("Successfully decoded data from \(url)")
                    return Just(decodedData)
                        .setFailureType(to: NetworkServiceError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("Decoding error for data from \(url): \(error)")
                    return Fail(error: NetworkServiceError.decodingError(error))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchEvents(for date: Date) -> AnyPublisher<[EventNetworkModel], NetworkServiceError> {
        guard let month = date.month, let day = date.day else {
            print("Invalid date components for fetching history")
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }

        guard let url = URL(string: "\(baseURL)/date/\(month)/\(day)") else {
            print("Invalid URL for date: \(date)")
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }

        print("Fetching history for date: \(date) with URL: \(url)")

        return fetchData(from: url)
            .map { (response: EventsNetworkModel) in
                return response.events
            }
            .eraseToAnyPublisher()
    }
}
