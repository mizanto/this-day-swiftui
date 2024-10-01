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
            VStack(spacing: 20) {
                if viewModel.isSignUpMode {
                    TextField("Enter your name", text: $viewModel.name)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                }

                TextField("Enter your e-mail", text: $viewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)

                SecureField("Enter your password", text: $viewModel.password)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isTextFieldFocused)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    if viewModel.isSignUpMode {
                        viewModel.signUp()
                    } else {
                        viewModel.signIn()
                    }
                }) {
                    Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    viewModel.isSignUpMode.toggle()
                }) {
                    Text(viewModel.isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
            .onChange(of: viewModel.isSignUpMode) { _, newValue in
                isTextFieldFocused = false
            }
        }
    }

    private func isValidName(_ name: String) -> Bool {
        !name.isEmpty && name.count >= 3
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(onAuthenticated: {}))
}
