//
//  BookmarksViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

final class BookmarksViewBuilder {
    static func build(storageService: StorageServiceProtocol,
                      localizationManager: any LocalizationManagerProtocol) -> some View {
        let viewModel = BookmarksViewModel(storageService: storageService,
                                           localizationManager: localizationManager)
        return BookmarksView(viewModel: viewModel)
    }
}
