//
//  AuthView.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import SwiftUI

struct AuthView<ViewModel: AuthViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @FocusState private var isTextFieldFocused: Bool

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                if viewModel.isSignUpMode {
                    TextField(LocalizedString("auth.enter_name"), text: $viewModel.name)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                }
                TextField(LocalizedString("auth.enter_email"), text: $viewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                SecureField(LocalizedString("auth.enter_password"), text: $viewModel.password)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                Button(
                    action: {
                        viewModel.onActionButtonTapped()
                    },
                    label: {
                        Text(viewModel.actionButtonTitle)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                )
                Button(
                    action: {
                        viewModel.changeAuthMode()
                    },
                    label: {
                        Text(viewModel.changeModeButtonTitle)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                )
                Spacer()
            }
            .padding(32)
            .navigationTitle(viewModel.title)
            .onChange(of: viewModel.isSignUpMode) {
                isTextFieldFocused = false
            }
        }
        .snackbar(isPresented: $viewModel.showErrorSnackbar, message: viewModel.snackbarErrorMessage, type: .error)
    }
}

#Preview {
    AuthView(
        viewModel: AuthViewModel(
            authService: AuthenticationService(),
            onAuthenticated: {}
        )
    )
}
