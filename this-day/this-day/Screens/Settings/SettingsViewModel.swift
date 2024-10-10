//
//  SettingsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import Foundation
import FirebaseAuth
import Combine
import UIKit

protocol SettingsViewModelProtocol: ObservableObject {
    var appVersion: String { get }
    var availableLanguages: [Language] { get }
    var selectedLanguage: String { get set }
    var currentUser: UserInfo? { get }
    var showSnackbar: Bool { get set }
    var isAuthenticated: Bool { get }
    var isUpdateAvailable: Bool { get }
    var appVersionMessage: String { get }

    func signOut()
    func updateLanguage(_ id: String)
    func updateApplication()
    func copyAppVersion()
}

final class SettingsViewModel: SettingsViewModelProtocol {
    @Published var selectedLanguage: String
    @Published var currentUser: UserInfo?
    @Published var showSnackbar = false

    var appVersion: String { "\(settings.appVersion) (\(settings.buildNumber))" }
    var availableLanguages: [Language] {
        [
            Language(id: "en", name: "English"),
            Language(id: "ru", name: "Русский")
        ]
    }
    var isAuthenticated: Bool { authService.isAuthenticated }
    var isUpdateAvailable: Bool { settings.isUpdateAvailable }
    var appVersionMessage: String { LocalizedString("message.snackbar.app_version") }

    private var settings: AppSettingsProtocol
    private var authService: AuthenticationServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private var onLogout: VoidClosure

    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettingsProtocol,
         authService: AuthenticationServiceProtocol,
         analyticsService: AnalyticsServiceProtocol,
         onLogout: @escaping VoidClosure) {
        self.settings = settings
        self.authService = authService
        self.selectedLanguage = settings.language
        self.analyticsService = analyticsService
        self.onLogout = onLogout

        bind()
    }

    func signOut() {
        authService
            .signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        AppLogger.shared.error("[Settings View]: Failed to sign out: \(error)", category: .auth)
                    }
                },
                receiveValue: { [weak self] in
                    guard let self else { return }
                    self.analyticsService.logEvent(.signout)
                    AppLogger.shared.debug("[Settings View]: Signed out successfully", category: .auth)
                    self.onLogout()
                }
            )
            .store(in: &cancellables)
    }

    func updateLanguage(_ id: String) {
        settings.language = id
        Bundle.setLanguage(id)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)

        objectWillChange.send()

        analyticsService.setUserProperty(.language, value: id)
        analyticsService.logEvent(.languageSelected, parameters: ["id": id])
    }

    func updateApplication() {
        guard let url = URL(string: self.settings.appStorePageURL) else { return }
        UIApplication.shared.open(url)
    }

    func copyAppVersion() {
        UIPasteboard.general.string = appVersion
        showSnackbar = true
    }

    private func bind() {
        authService.currentUserPublisher
            .compactMap { .init(model: $0) }
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
}
