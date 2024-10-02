//
//  AuthenticationService.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import Combine
import FirebaseAuth
import FirebaseAuthCombineSwift

protocol AuthenticationServiceProtocol {
    var currentUser: UserInfoModel? { get }
    var isAuthenticated: Bool { get }
    var currentUserPublisher: AnyPublisher<UserInfoModel?, Never> { get }

    func signIn(email: String, password: String) -> AnyPublisher<Void, AuthenticationError>
    func signUp(name: String, email: String, password: String) -> AnyPublisher<Void, AuthenticationError>
    func signOut() -> AnyPublisher<Void, AuthenticationError>
}

final class AuthenticationService: AuthenticationServiceProtocol {
    @Published var currentUser: UserInfoModel?

    var isAuthenticated: Bool { Auth.auth().currentUser != nil }
    var currentUserPublisher: AnyPublisher<UserInfoModel?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        Auth.auth().authStateDidChangePublisher()
            .sink { [weak self] user in
                if let user = user {
                    self?.currentUser = UserInfoModel(name: user.displayName ?? "",
                                                 email: user.email ?? "")
                } else {
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
    }

    func signIn(email: String, password: String) -> AnyPublisher<Void, AuthenticationError> {
        guard isEmailValid(email) else {
            return Fail(error: AuthenticationError.invalidEmail).eraseToAnyPublisher()
        }

        guard isPasswordValid(password) else {
            return Fail(error: AuthenticationError.weakPassword).eraseToAnyPublisher()
        }

        return Auth.auth()
            .signIn(withEmail: email, password: password)
            .map { _ in () }
            .mapError { error in
                AppLogger.shared.error("Error signing in user: \(error.localizedDescription)", category: .auth)
                return AuthenticationError.loginFailed
            }
            .eraseToAnyPublisher()
    }

    func signUp(name: String, email: String, password: String) -> AnyPublisher<Void, AuthenticationError> {
        guard isNameValid(name) else {
            return Fail(error: AuthenticationError.invalidName).eraseToAnyPublisher()
        }

        guard isEmailValid(email) else {
            return Fail(error: AuthenticationError.invalidEmail).eraseToAnyPublisher()
        }

        guard isPasswordValid(password) else {
            return Fail(error: AuthenticationError.weakPassword).eraseToAnyPublisher()
        }

        return Auth.auth()
            .createUser(withEmail: email, password: password)
            .mapError { error in
                AppLogger.shared.error("Error signing up user: \(error.localizedDescription)", category: .auth)
                return AuthenticationError.creationFailed
            }
            .flatMap { authResult -> AnyPublisher<Void, AuthenticationError> in
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = name

                return Future<Void, AuthenticationError> { promise in
                    changeRequest.commitChanges { error in
                        if let error = error {
                            AppLogger.shared.error("Failed to update profile: \(error.localizedDescription)",
                                                   category: .auth)
                            promise(.failure(AuthenticationError.updateFailed))
                        } else {
                            promise(.success(()))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func signOut() -> AnyPublisher<Void, AuthenticationError> {
        return Future<Void, AuthenticationError> { promise in
            do {
                try Auth.auth().signOut()
                AppLogger.shared.info("Sign out successful", category: .auth)
                promise(.success(()))
            } catch let error {
                AppLogger.shared.error("Sign out failed: \(error)", category: .auth)
                promise(.failure(AuthenticationError.logoutFailed))
            }
        }
        .eraseToAnyPublisher()
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
}
