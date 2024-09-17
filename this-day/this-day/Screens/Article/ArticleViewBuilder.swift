//
//  ArticleViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import SwiftUI

final class ArticleViewBuilder {
    static func build(topic: String) -> some View {
        guard let wikipediaService: WikipediaServiceProtocol = DIContainer.shared.resolve() else {
            fatalError("WikipediaService not registered in DI Container")
        }

        let viewModel = ArticleViewModel(topic: topic, wikipediaService: wikipediaService)
        return ArticleView(viewModel: viewModel)
    }
}
