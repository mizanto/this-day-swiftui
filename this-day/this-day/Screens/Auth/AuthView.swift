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
    @State private var isPresentingPrivacyPolicy = false

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
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
                        .foregroundColor(.appRed)
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
                            .background(viewModel.actionButtonIsActive ? .main : .unavailable)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                )
                .disabled(!viewModel.actionButtonIsActive)

                if viewModel.isSignUpMode {
                    Toggle(isOn: $viewModel.isPolicyAccepted) {
                        Text(LocalizedString("auth.text.policy"))
                            .underline()
                            .font(.footnote)
                            .onTapGesture {
                                isPresentingPrivacyPolicy = true
                            }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .main))
                }
                Button(
                    action: {
                        viewModel.changeAuthMode()
                    },
                    label: {
                        Text(viewModel.changeModeButtonTitle)
                            .font(.footnote)
                            .foregroundColor(.main)
                    }
                )
            }
            .padding(32)
            .frame(maxHeight: .infinity, alignment: .center)
            .navigationTitle(viewModel.title)
            .onChange(of: viewModel.isSignUpMode) {
                isTextFieldFocused = false
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isPresentingPrivacyPolicy) {
            PrivacyPolicyView(language: viewModel.currentLanguage)
        }
        .snackbar(isPresented: $viewModel.showErrorSnackbar, message: viewModel.snackbarErrorMessage, type: .error)
    }
}

#Preview {
    AuthView(
        viewModel: AuthViewModel(
            authService: AuthenticationService(),
            settings: AppSettings.shared,
            analyticsService: AnalyticsService.shared,
            onAuthenticated: {}
        )
    )
}
