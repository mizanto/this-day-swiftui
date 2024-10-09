//
//  BookmarksViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

final class BookmarksViewBuilder {
    static func build(dataRepository: DataRepositoryProtocol,
                      localizationManager: any LocalizationManagerProtocol,
                      analyticsService: AnalyticsServiceProtocol) -> some View {
        let viewModel = BookmarksViewModel(dataRepository: dataRepository,
                                           localizationManager: localizationManager,
                                           analyticsService: analyticsService)
        return BookmarksView(viewModel: viewModel)
    }
}
