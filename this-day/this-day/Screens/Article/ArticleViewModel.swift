//
//  ArticleViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

protocol ArticleViewModelProtocol: ObservableObject {
    var state: ViewState<Article> { get }
    var title: String { get }
    func fetchArticle()
}

class ArticleViewModel: ArticleViewModelProtocol {
    @Published var state: ViewState<Article> = .loading
    @Published var title: String

    private let wikipediaService: WikipediaService
    private var cancellables = Set<AnyCancellable>()

    init(topic: String, wikipediaService: WikipediaService = WikipediaService()) {
        self.title = topic
        self.wikipediaService = wikipediaService
    }

    func fetchArticle() {
        let topic = title.replacingOccurrences(of: " ", with: "_")
        state = .loading

        let fetchTextPublisher = wikipediaService.fetchArticle(title: topic)

        // Ignore an error, the image is optional
        let fetchImagePublisher = wikipediaService.fetchImage(title: topic)
            .catch { error -> AnyPublisher<String, NetworkServiceError> in
                AppLogger.shared.error("Failed to fetch image for topic \(topic): \(error.localizedDescription)", category: .ui)
                return Just("")
                    .setFailureType(to: NetworkServiceError.self)
                    .eraseToAnyPublisher()
            }

        fetchTextPublisher
            .combineLatest(fetchImagePublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.state = .error("Failed to fetch data for topic \(topic): \(error.localizedDescription)")
                        AppLogger.shared.error("Failed to fetch text for topic \(topic): \(error)", category: .ui)
                    case .finished:
                        AppLogger.shared.info("Successfully fetched data for topic \(topic)", category: .ui)
                    }
                },
                receiveValue: { [weak self] articleText, articleImageURL in
                    if articleText.isEmpty {
                        // Показываем ошибку, если текст статьи не пришел
                        self?.state = .error("Article text not found for topic \(topic).")
                    } else {
                        // Обновляем состояние только если текст статьи загружен
                        let imageURL = articleImageURL.isEmpty ? nil : URL(string: articleImageURL)
                        let article = Article(text: articleText, imageURL: imageURL)
                        self?.state = .loaded(article)
                    }
                }
            )
            .store(in: &cancellables)
    }
}
