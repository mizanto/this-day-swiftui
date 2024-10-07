//
//  SettingsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import Foundation
import FirebaseAuth
import Combine
import SwiftUI

protocol SettingsViewModelProtocol: ObservableObject {
    associatedtype AuthViewType: View
    var appVersion: String { get }
    var buildNumber: String { get }
    var availableLanguages: [Language] { get }
    var selectedLanguage: String { get set }
    var currentUser: UserInfo? { get }
    var isAuthenticated: Bool { get }

    func signOut()
    func updateLanguage(_ languageId: String)
    func makeAuthView(onAuthenticated: @escaping VoidClosure) -> AuthViewType
}

final class SettingsViewModel: SettingsViewModelProtocol {
    @Published var selectedLanguage: String
    @Published var currentUser: UserInfo?

    var appVersion: String { Bundle.main.versionNumber }
    var buildNumber: String { Bundle.main.buildNumber }
    var availableLanguages: [Language] { localizationManager.availableLanguages }
    var isAuthenticated: Bool { authService.isAuthenticated }

    private var authService: AuthenticationServiceProtocol
    private var localizationManager: any LocalizationManagerProtocol
    private var onLogout: VoidClosure

    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthenticationServiceProtocol,
         localizationManager: any LocalizationManagerProtocol,
         onLogout: @escaping VoidClosure) {
        self.authService = authService
        self.localizationManager = localizationManager
        self.selectedLanguage = localizationManager.currentLanguage
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
                        AppLogger.shared.error("Failed to sign out: \(error)", category: .auth)
                    }
                },
                receiveValue: { [weak self] in
                    guard let self else { return }
                    AppLogger.shared.info("Signed out successfully", category: .auth)
                    self.onLogout()
                }
            )
            .store(in: &cancellables)
    }

    func updateLanguage(_ languageId: String) {
        localizationManager.currentLanguage = languageId
        selectedLanguage = languageId
    }

    func makeAuthView(onAuthenticated: @escaping VoidClosure) -> some View {
        AuthViewBuilder.build(authService: authService, onAuthenticated: onAuthenticated)
    }

    private func bind() {
        authService.currentUserPublisher
            .compactMap { .init(model: $0) }
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
}
