//
//  BookmarksViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

final class BookmarksViewBuilder {
    static func build(dataRepository: DataRepositoryProtocol,
                      settings: AppSettingsProtocol,
                      analyticsService: AnalyticsServiceProtocol) -> some View {
        let viewModel = BookmarksViewModel(dataRepository: dataRepository,
                                           settings: settings,
                                           analyticsService: analyticsService)
        return BookmarksView(viewModel: viewModel)
    }
}
