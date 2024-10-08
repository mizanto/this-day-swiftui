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

    var isAuthenticated: Bool { currentUser != nil }
    var currentUserPublisher: AnyPublisher<UserInfoModel?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private var keychain: KeychainHelper = .shared
    private let keychainService: String = "com.thisday.service"
    private let keychainAccount: String = "user_info"

    private var cancellables = Set<AnyCancellable>()

    init() {
        Auth.auth().authStateDidChangePublisher()
            .sink { [weak self] user in
                guard let self else { return }
                if let user = user {
                    self.currentUser = UserInfoModel(from: user)
                    AppLogger.shared.info("[Auth]: User signed in: \(String(describing: self.currentUser))")
                } else {
                    self.currentUser = nil
                    AppLogger.shared.info("[Auth]: User signed out")
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
                AppLogger.shared.error("[Auth]: Error signing in user: \(error.localizedDescription)", category: .auth)
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
                            AppLogger.shared.error("[Auth]: Failed to update profile: \(error.localizedDescription)",
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
                AppLogger.shared.info("[Auth]: Sign out successful", category: .auth)
                promise(.success(()))
            } catch let error {
                AppLogger.shared.error("[Auth]: Sign out failed: \(error)", category: .auth)
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

    private func saveUserInfoToKeychain(_ user: UserInfoModel) {
        if let data = try? JSONEncoder().encode(user) {
            keychain.save(service: keychainService, account: keychainAccount, data: data)
            AppLogger.shared.info("[Auth]: User info saved to Keychain", category: .auth)
        } else {
            AppLogger.shared.error("[Auth]: Failed to encode user info", category: .auth)
        }
    }

    private func readUserInfoFromKeychain() -> UserInfoModel? {
        guard let data = keychain.read(service: keychainService, account: keychainAccount) else {
            AppLogger.shared.info("[Auth]: No credentials found in Keychain", category: .auth)
            return nil
        }
        return try? JSONDecoder().decode(UserInfoModel.self, from: data)
    }

    private func removeUserInfoFromKeychain() {
        keychain.delete(service: keychainService, account: keychainAccount)
        AppLogger.shared.info("[Auth]: Credentials deleted from Keychain", category: .auth)
    }
}

import Security

final class KeychainHelper {

    static let shared = KeychainHelper()

    private init() {}

    func save(service: String, account: String, data: Data) {
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // Password class
            kSecAttrService as String: service,            // Service identifier
            kSecAttrAccount as String: account,            // Account identifier
            kSecValueData as String: data                  // Data to store
        ]

        // Delete any existing items
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    func read(service: String, account: String) -> Data? {
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,                // Return data
            kSecMatchLimit as String: kSecMatchLimitOne    // Only one item
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        } else {
            print("Keychain read error: \(status)")
            return nil
        }
    }

    func delete(service: String, account: String) {
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess {
            print("Keychain delete error: \(status)")
        }
    }
}
