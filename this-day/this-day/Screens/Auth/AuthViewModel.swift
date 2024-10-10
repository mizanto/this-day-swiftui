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
    var showErrorSnackbar: Bool { get set }
    var snackbarErrorMessage: String { get }
    var isPolicyAccepted: Bool { get set }
    var actionButtonIsActive: Bool { get }
    var currentLanguage: String { get }

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
    @Published var showErrorSnackbar = false
    @Published var isPolicyAccepted = false

    var snackbarErrorMessage: String = ""

    var onAuthenticated: VoidClosure

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

    var actionButtonIsActive: Bool { (isSignUpMode && isPolicyAccepted) || !isSignUpMode }
    var currentLanguage: String { settings.language }

    private let authService: AuthenticationServiceProtocol
    private let settings: AppSettingsProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthenticationServiceProtocol,
         settings: AppSettingsProtocol,
         analyticsService: AnalyticsServiceProtocol,
         onAuthenticated: @escaping VoidClosure) {
        self.authService = authService
        self.settings = settings
        self.analyticsService = analyticsService
        self.onAuthenticated = onAuthenticated

        bind()
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

    private func bind() {
        $isAuthenticated
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in self?.onAuthenticated() }
            .store(in: &cancellables)

        $isSignUpMode
            .sink { [ weak self] _ in self?.clearInputs() }
            .store(in: &cancellables)
    }

    private func signIn() {
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("[Auth View]: Sign in failed: \(error)", category: .auth)
                        self?.processError(error: error)
                    }
                },
                receiveValue: { [weak self] in
                    AppLogger.shared.debug("[Auth View]: Sign in successful", category: .auth)
                    self?.isAuthenticated = true
                    self?.analyticsService.logEvent(.login)
                    if let id = self?.authService.currentUser?.id {
                        self?.analyticsService.setUserId(id)
                    } else {
                        AppLogger.shared.error("[Auth View]: No user id found", category: .auth)
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func signUp() {
        authService.signUp(name: name, email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("[Auth View]: Sign up failed: \(error)", category: .auth)
                        self?.processError(error: error)
                    }
                },
                receiveValue: { [weak self] in
                    AppLogger.shared.debug("[Auth View]: Sign up successful", category: .auth)
                    self?.isAuthenticated = true
                    self?.analyticsService.logEvent(.signup)
                    if let id = self?.authService.currentUser?.id {
                        self?.analyticsService.setUserId(id)
                    } else {
                        AppLogger.shared.error("[Auth View]: No user id found", category: .auth)
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func clearInputs() {
        name = ""
        email = ""
        password = ""
        errorMessage = nil
    }

    private func processError(error: AuthenticationError) {
        switch error {
        case .invalidName:
            errorMessage = LocalizedString("auth.validation_error.name_length")
        case .invalidEmail:
            errorMessage = LocalizedString("auth.validation_error.email")
        case .weakPassword:
            errorMessage = LocalizedString("auth.validation_error.password_length") + "\n"
            + LocalizedString("auth.validation_error.password_upper_case") + "\n"
            + LocalizedString("auth.validation_error.password_digit")
        case .loginFailed:
            snackbarErrorMessage = LocalizedString("auth.login_error")
            showErrorSnackbar = true
        case .creationFailed:
            snackbarErrorMessage = LocalizedString("auth.registration_error")
            showErrorSnackbar = true
        default:
            snackbarErrorMessage = LocalizedString("unknown_error")
            showErrorSnackbar = true
        }
    }
}
