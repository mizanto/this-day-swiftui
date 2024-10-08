//
//  NetworkService.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Combine
import Foundation

protocol NetworkServiceProtocol {
    func fetchEvents(for date: Date, language: String) -> AnyPublisher<DayNetworkModel, NetworkError>
}

class NetworkService: NetworkServiceProtocol {

    let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    private func fetchData<T: Decodable>(from url: URL) -> AnyPublisher<T, NetworkError> {
        return session.performRequestPublisher(for: url)
            .mapError { error in
                AppLogger.shared.error(
                    "[Network]: Network error occurred: \(error.localizedDescription)", category: .network)
                return NetworkError.networkError(error)
            }
            .flatMap { data, _ in
                Just(data)
                    .decode(type: T.self, decoder: JSONDecoder())
                    .mapError { error in
                        AppLogger.shared.error(
                            "[Network]: Decoding error occurred: \(error.localizedDescription)", category: .network)
                        return NetworkError.decodingError(error)
                    }
            }
            .eraseToAnyPublisher()
    }

    func fetchEvents(for date: Date, language: String = "en") -> AnyPublisher<DayNetworkModel, NetworkError> {
        guard let url = url(date: date, language: language) else {
            AppLogger.shared.error("Invalid URL for Wikipedia query with date: \(date)", category: .network)
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        AppLogger.shared.debug(
            "[Network]: Fetching Wikipedia events for date: \(date) with URL: \(url)", category: .network)

        return fetchData(from: url) // Use the generic fetch method
            .tryMap { (response: ResponseNetworkModel) in
                guard let extract = response.query.pages.values.first?.extract else {
                    AppLogger.shared.error("[Network]: Extract not found in the Wikipedia response", category: .network)
                    throw NetworkError.parsingError("Extract not found in the Wikipedia response")
                }
                return try WikipediaParser(language: language).parseWikipediaDay(from: extract)
            }
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.unknownError(error.localizedDescription)
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
