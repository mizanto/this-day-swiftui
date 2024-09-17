//
//  BaseNetworkService.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

class BaseNetworkService {
    let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    /// Method to fetch and decode data from a given URL
    func fetchData<T: Decodable>(from url: URL) -> AnyPublisher<T, NetworkServiceError> {
        AppLogger.shared.info("Fetching data from URL: \(url)", category: .network)

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
}
