//
//  AuthViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import Combine
import FirebaseAuth

protocol AuthViewModelProtocol: ObservableObject {
    var name: String { get set }
    var email: String { get set }
    var password: String { get set }
    var isSignUpMode: Bool { get set }
    var errorMessage: String? { get }
    var isAuthenticated: Bool { get set }
    var title: String { get }
    var actionButtonTitle: String { get }
    var changeModeButtonTitle: String { get }

    func onActionButtonTapped()
    func changeAuthMode()
}

final class AuthViewModel: AuthViewModelProtocol {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSignUpMode: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false

    var onAuthenticated: () -> Void
    
    var title: String {
        isSignUpMode ? LocalizedString("auth.title.sing_up")
                     : LocalizedString("auth.title.sign_in")
    }
    var actionButtonTitle: String {
        isSignUpMode ? LocalizedString("auth.button.sign_up")
                     : LocalizedString("auth.button.sign_in")
    }
    
    var changeModeButtonTitle: String {
        isSignUpMode ? LocalizedString("auth.button.already_have_account")
                     : LocalizedString("auth.button.dont_have_account")
    }

    private var cancellables = Set<AnyCancellable>()

    init(onAuthenticated: @escaping () -> Void) {
        self.onAuthenticated = onAuthenticated

        $isAuthenticated
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in self?.onAuthenticated() }
            .store(in: &cancellables)
        
        $isSignUpMode
            .sink { [ weak self] _ in self?.clearInputs() }
            .store(in: &cancellables)
    }
    
    func onActionButtonTapped() {
        if isSignUpMode {
            signUp()
        } else {
            signIn()
        }
    }
    
    func changeAuthMode() {
        isSignUpMode.toggle()
    }

    private func signIn() {
        if let validationError = validationMessage(isEmailValid: isEmailValid(email),
                                                   isPasswordValid: isPasswordValid(password)) {
            errorMessage = validationError
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                AppLogger.shared.error("Sign in failed: \(error)", category: .auth)
                self?.errorMessage = error.localizedDescription
            } else if authResult?.user != nil {
                AppLogger.shared.info("Sign in successful", category: .auth)
                self?.isAuthenticated = true
            }
        }
    }

    private func signUp() {
        if let validationError = validationMessage(isNameValid: isNameValid(name),
                                                   isEmailValid: isEmailValid(email),
                                                   isPasswordValid: isPasswordValid(password)) {
            errorMessage = validationError
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                AppLogger.shared.error("Sign up failed: \(error)", category: .auth)
                self?.errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
                AppLogger.shared.info("Sign up successful", category: .auth)
                self?.updateName(for: user)
            }
        }
    }

    private func updateName(for user: User) {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                AppLogger.shared.error("Failed to set display name: \(error)", category: .auth)
                self?.errorMessage = error.localizedDescription
            } else {
                AppLogger.shared.info("Display name set successfully", category: .auth)
            }
            self?.isAuthenticated = true
        }
    }

    private func isNameValid(_ name: String) -> Bool {
        return !name.isEmpty && name.count >= 3 && name.count <= 20
    }

    private func isEmailValid(_ email: String) -> Bool {
        let emailPattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        if email.range(of: emailPattern, options: .regularExpression) != nil {
            return true
        } else {
            return false
        }
    }

    private func isPasswordValid(_ password: String) -> Bool {
        // Ensure the password is at least 8 characters long
        guard password.count >= 8 else { return false }

        // Check for at least one uppercase letter
        let uppercasePattern = ".*[A-Z]+.*"
        guard password.range(of: uppercasePattern, options: .regularExpression) != nil else { return false }

        // Check for at least one digit
        let digitPattern = ".*[0-9]+.*"
        guard password.range(of: digitPattern, options: .regularExpression) != nil else { return false }

        return true
    }

    private func validationMessage(isNameValid: Bool = true, isEmailValid: Bool, isPasswordValid: Bool) -> String? {
        var message: String = ""
        if !isNameValid {
            message += LocalizedString("auth.validation_error.name_length") + "\n"
        }
        if !isEmailValid {
            message += LocalizedString("auth.validation_error.email") + "\n"
        }
        if !isPasswordValid {
            message += LocalizedString("auth.validation_error.password_length") + "\n"
            message += LocalizedString("auth.validation_error.password_upper_case") + "\n"
            message += LocalizedString("auth.validation_error.password_digit") + "\n"
        }
        return message.isEmpty ? nil : message
    }

    private func clearInputs() {
        name = ""
        email = ""
        password = ""
        errorMessage = nil
    }
}
