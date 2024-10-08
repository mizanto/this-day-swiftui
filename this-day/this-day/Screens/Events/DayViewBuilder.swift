//
//  DayViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class DayViewBuilder {
    static func build(dataRepository: DataRepositoryProtocol,
                      localizationManager: any LocalizationManagerProtocol) -> some View {
        let viewModel = DayViewModel(dataRepository: dataRepository,
                                     localizationManager: localizationManager)
        return DayView(viewModel: viewModel)
    }
}
