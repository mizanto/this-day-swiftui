//
//  NetworkService.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Combine
import Foundation

protocol NetworkServiceProtocol {
    func fetchEvents(for date: Date) -> AnyPublisher<DayNetworkModel, NetworkServiceError>
}

class NetworkService: NetworkServiceProtocol {

    let parser: WikipediaParser
    let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.parser = WikipediaParser()
    }

    func fetchEvents(for date: Date) -> AnyPublisher<DayNetworkModel, NetworkServiceError> {
        let formattedDate = date.toFormat("MMMM_dd")

        // swiftlint:disable:next line_length
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&titles=\(formattedDate)&explaintext=true"

        guard let url = URL(string: urlString) else {
            AppLogger.shared.error("Invalid URL for Wikipedia query with date: \(date)", category: .network)
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }

        AppLogger.shared.info("Fetching Wikipedia events for date: \(date) with URL: \(url)", category: .network)

        return session.performRequestPublisher(for: url)
            .mapError { error in
                AppLogger.shared.error("Network error occurred: \(error.localizedDescription)", category: .network)
                return NetworkServiceError.networkError(error)
            }
            .tryMap { [weak self] data, response in
                guard let self else {
                    throw NetworkServiceError.unknownError("Self is nil in parsing step")
                }

                AppLogger.shared.debug("Recing response from Wikipedia for date: \(response)")
                AppLogger.shared.info("Received data from Wikipedia for date: \(date)", category: .network)

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    guard let query = json?["query"] as? [String: Any],
                          let pages = query["pages"] as? [String: Any],
                          let page = pages.values.first as? [String: Any],
                          let extract = page["extract"] as? String else {
                        AppLogger.shared.error("Failed to extract 'extract' key from Wikipedia response", category: .network)
                        throw NetworkServiceError.decodingError(URLError(.badServerResponse))
                    }
                    
                    AppLogger.shared.info("Successfully extracted 'extract' for date: \(date)", category: .network)
                    
                    return try self.parser.parseWikipediaDay(from: extract)
                } catch let error as DecodingError {
                    AppLogger.shared.error("JSON decoding error occurred: \(error.localizedDescription)", category: .network)
                    throw NetworkServiceError.decodingError(error)
                } catch {
                    AppLogger.shared.error("Unexpected error occurred: \(error.localizedDescription)", category: .network)
                    throw NetworkServiceError.decodingError(error)
                }
            }
            .mapError { error -> NetworkServiceError in
                if let networkError = error as? NetworkServiceError {
                    return networkError
                } else {
                    return NetworkServiceError.unknownError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}
