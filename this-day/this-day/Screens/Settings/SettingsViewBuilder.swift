//
//  SettingsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

final class SettingsViewBuilder {
    static func build(authService: AuthenticationServiceProtocol,
                      localizationManager: any LocalizationManagerProtocol,
                      analyticsService: AnalyticsServiceProtocol,
                      onLogout: @escaping VoidClosure) -> some View {
        let viewModel = SettingsViewModel(authService: authService,
                                          localizationManager: localizationManager,
                                          analyticsService: analyticsService,
                                          onLogout: onLogout)
        return SettingsView(viewModel: viewModel)
    }
}
