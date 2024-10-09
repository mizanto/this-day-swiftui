//
//  DayViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class DayViewBuilder {
    static func build(dataRepository: DataRepositoryProtocol,
                      localizationManager: any LocalizationManagerProtocol,
                      analyticsService: AnalyticsServiceProtocol) -> some View {
        let viewModel = DayViewModel(dataRepository: dataRepository,
                                     localizationManager: localizationManager,
                                     analyticsService: analyticsService)
        return DayView(viewModel: viewModel)
    }
}
