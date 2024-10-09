//
//  DayViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class DayViewBuilder {
    static func build(dataRepository: DataRepositoryProtocol,
                      settings: AppSettingsProtocol,
                      analyticsService: AnalyticsServiceProtocol) -> some View {
        let viewModel = DayViewModel(dataRepository: dataRepository,
                                     settings: settings,
                                     analyticsService: analyticsService)
        return DayView(viewModel: viewModel)
    }
}
