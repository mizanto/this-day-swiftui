//
//  WikipediaURLBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 22.09.2024.
//

import Foundation

final class WikipediaURLBuilder {
    private let scheme = "https"
    private let host = "en.wikipedia.org"
    private let path = "/w/api.php"

    private var urlComponents: URLComponents

    init() {
        urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = []
    }

    func addQueryParameter(name: String, value: String) -> Self {
        urlComponents.queryItems?.append(URLQueryItem(name: name, value: value))
        return self
    }

    func action(_ action: String) -> Self {
        addQueryParameter(name: "action", value: action)
    }

    func prop(_ prop: String) -> Self {
        addQueryParameter(name: "prop", value: prop)
    }

    func format(_ format: String) -> Self {
        addQueryParameter(name: "format", value: format)
    }

    func titles(_ titles: String) -> Self {
        addQueryParameter(name: "titles", value: titles)
    }

    func explaintext(_ explaintext: Bool) -> Self {
        addQueryParameter(name: "explaintext", value: String(explaintext))
    }

    func build() -> URL? {
        return urlComponents.url
    }
}
