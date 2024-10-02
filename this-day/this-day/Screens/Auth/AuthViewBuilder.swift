//
//  AuthViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import SwiftUI

final class AuthViewBuilder {
    static func build(authService: AuthenticationServiceProtocol, onAuthenticated: @escaping () -> Void) -> some View {
        let viewModel = AuthViewModel(authService: authService, onAuthenticated: onAuthenticated)
        return AuthView(viewModel: viewModel)
    }
}
