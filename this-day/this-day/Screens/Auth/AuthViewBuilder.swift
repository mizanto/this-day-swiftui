//
//  AuthViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import SwiftUI

final class AuthViewBuilder {
    static func build(authService: AuthenticationServiceProtocol,
                      settings: AppSettingsProtocol,
                      analyticsService: AnalyticsServiceProtocol,
                      onAuthenticated: @escaping VoidClosure) -> some View {
        let viewModel = AuthViewModel(authService: authService,
                                      settings: settings,
                                      analyticsService: analyticsService,
                                      onAuthenticated: onAuthenticated)
        return AuthView(viewModel: viewModel)
    }
}
