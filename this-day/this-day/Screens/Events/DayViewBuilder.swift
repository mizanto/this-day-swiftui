//
//  DayViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class DayViewBuilder {
    static func build(networkService: NetworkServiceProtocol,
                      storageService: LocalStorageProtocol,
                      localizationManager: any LocalizationManagerProtocol) -> some View {
        let viewModel = DayViewModel(networkService: networkService,
                                     storageService: storageService,
                                     localizationManager: localizationManager)
        return DayView(viewModel: viewModel)
    }
}
