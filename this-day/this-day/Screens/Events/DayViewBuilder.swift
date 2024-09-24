//
//  DayViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

final class DayViewBuilder {
    static func build(networkService: NetworkServiceProtocol,
                      storageService: StorageServiceProtocol) -> some View {
        let viewModel = DayViewModel(networkService: networkService,
                                     storageService: storageService)
        return DayView(viewModel: viewModel)
    }
}
