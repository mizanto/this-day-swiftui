//
//  WikipediaService.swift
//  this-day
//
//  Created by Sergey Bendak on 19.09.2024.
//

import Combine
import Foundation

struct WikipediaDay {
    let text: String
    let events: [WikipediaEvent]
    let births: [WikipediaEvent]
    let deaths: [WikipediaEvent]
    let holidays: [WikipediaEvent]
}

struct WikipediaEvent: Codable {
    let title: String
    let text: String
}

struct WikipediaResponse: Codable {
    let extract: String
}

protocol WikipediaServiceProtocol {
    func fetchEvents(for date: Date) -> AnyPublisher<WikipediaDay, Error>
}

class WikipediaService: WikipediaServiceProtocol {
    
    let parser: WikiParser
    let session: URLSessionProtocol
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.parser = WikiParser()
    }
    
    func fetchEvents(for date: Date) -> AnyPublisher<WikipediaDay, Error> {
        let formattedDate = date.toFormat("MMMM_dd")
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&titles=\(formattedDate)&explaintext=true"
        
        guard let url = URL(string: urlString) else {
            AppLogger.shared.error("Invalid URL for Wikipedia query with date: \(date)", category: .network)
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        AppLogger.shared.info("Fetching Wikipedia events for date: \(date) with URL: \(url)", category: .network)
        
        return session.performRequestPublisher(for: url)
            .tryMap { [weak self] data, response in
                guard let self else {
                    throw URLError(.badServerResponse)
                }
                
                AppLogger.shared.info("Received data from Wikipedia for date: \(date)", category: .network)
                
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                guard let query = json?["query"] as? [String: Any],
                      let pages = query["pages"] as? [String: Any],
                      let page = pages.values.first as? [String: Any],
                      let extract = page["extract"] as? String else {
                    AppLogger.shared.error("Failed to extract 'extract' key from Wikipedia response", category: .network)
                    throw URLError(.badServerResponse)
                }
                
                AppLogger.shared.info("Successfully extracted 'extract' for date: \(date)", category: .network)
                
                return try self.parser.parseWikipediaDay(from: extract)
            }
            .catch { error -> Fail<WikipediaDay, Error> in
                AppLogger.shared.error("Failed to fetch Wikipedia events for date: \(date). Error: \(error.localizedDescription)", category: .network)
                return Fail(error: error)
            }
            .eraseToAnyPublisher()
    }
}
