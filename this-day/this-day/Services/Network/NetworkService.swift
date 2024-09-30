//
//  NetworkService.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Combine
import Foundation

protocol NetworkServiceProtocol {
    func fetchEvents(for date: Date, language: String) -> AnyPublisher<DayNetworkModel, NetworkServiceError>
}

class NetworkService: NetworkServiceProtocol {

    let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    private func fetchData<T: Decodable>(from url: URL) -> AnyPublisher<T, NetworkServiceError> {
        return session.performRequestPublisher(for: url)
            .mapError { error in
                AppLogger.shared.error("Network error occurred: \(error.localizedDescription)", category: .network)
                return NetworkServiceError.networkError(error)
            }
            .flatMap { data, _ in
                Just(data)
                    .decode(type: T.self, decoder: JSONDecoder())
                    .mapError { error in
                        AppLogger.shared.error("Decoding error occurred: \(error.localizedDescription)",
                                               category: .network)
                        return NetworkServiceError.decodingError(error)
                    }
            }
            .eraseToAnyPublisher()
    }

    func fetchEvents(for date: Date, language: String) -> AnyPublisher<DayNetworkModel, NetworkServiceError> {
        guard let url = url(date: date, language: language) else {
            AppLogger.shared.error("Invalid URL for Wikipedia query with date: \(date)", category: .network)
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }
        AppLogger.shared.info("Fetching Wikipedia events for date: \(date) with URL: \(url)", category: .network)

        return fetchData(from: url) // Use the generic fetch method
            .tryMap { (response: ResponseNetworkModel) in
                guard let extract = response.query.pages.values.first?.extract else {
                    AppLogger.shared.error("Extract not found in the Wikipedia response", category: .network)
                    throw NetworkServiceError.parsingError("Extract not found in the Wikipedia response")
                }

                AppLogger.shared.info("Successfully extracted 'extract' for date: \(date)", category: .network)
                return try WikipediaParser(language: language).parseWikipediaDay(from: extract)
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

    private func url(date: Date, language: String) -> URL? {
        WikipediaURLBuilder(language: language)
            .action("query")
            .prop("extracts")
            .format("json")
            .titles(date.toLocalizedDayMonth(language: language))
            .explaintext(true)
            .build()
    }
}
