//
//  SettingsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

final class SettingsViewBuilder {
    static func build(settings: AppSettingsProtocol,
                      authService: AuthenticationServiceProtocol,
                      analyticsService: AnalyticsServiceProtocol,
                      onLogout: @escaping VoidClosure) -> some View {
        let viewModel = SettingsViewModel(settings: settings,
                                          authService: authService,
                                          analyticsService: analyticsService,
                                          onLogout: onLogout)
        return SettingsView(viewModel: viewModel)
    }
}
