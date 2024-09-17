//
//  WikipediaService.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

protocol WikipediaServiceProtocol {
    func fetchArticle(title: String) -> AnyPublisher<String, NetworkServiceError>
    func fetchImage(title: String) -> AnyPublisher<String, NetworkServiceError>
}

final class WikipediaService: BaseNetworkService, WikipediaServiceProtocol {
    private let baseURL = "https://en.wikipedia.org/w/api.php"

    func fetchArticle(title: String) -> AnyPublisher<String, NetworkServiceError> {
        guard let url = URL(string: "\(baseURL)?action=query&prop=extracts&explaintext&format=json&titles=\(title)") else {
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }

        return fetchData(from: url)
            .tryMap { (response: WKResponseNetworkModel) -> String in
                guard let extract = response.query.pages.values.first?.extract else {
                    throw NetworkServiceError.decodingError(
                        NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Article text not found."])
                    )
                }
                return extract
            }
            .mapError { error in
                error as? NetworkServiceError ?? NetworkServiceError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }

    func fetchImage(title: String) -> AnyPublisher<String, NetworkServiceError> {
        guard let url = URL(string: "\(baseURL)?action=query&prop=pageimages&format=json&piprop=thumbnail|original&pithumbsize=500&titles=\(title)") else {
            return Fail(error: NetworkServiceError.invalidURL).eraseToAnyPublisher()
        }

        return fetchData(from: url)
            .tryMap { (response: WKResponseNetworkModel) -> String in
                guard let imageUrl = response.query.pages.values.first?.thumbnail?.source else {
                    throw NetworkServiceError.decodingError(
                        NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Article image not found."])
                    )
                }
                return imageUrl
            }
            .mapError { error in
                error as? NetworkServiceError ?? NetworkServiceError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }
}
