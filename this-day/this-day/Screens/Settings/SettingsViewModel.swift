//
//  SettingsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import Foundation
import FirebaseAuth

struct UserInfo {
    let name: String
    let email: String
}

protocol SettingsViewModelProtocol: ObservableObject {
    var appVersion: String { get }
    var buildNumber: String { get }
    var availableLanguages: [Language] { get }
    var selectedLanguage: String { get set }
    var currentUser: UserInfo? { get }

    func signOut()
    func updateProfileName(_ name: String)
    func updateLanguage(_ languageId: String)
    func refreshUserData()
}

final class SettingsViewModel: SettingsViewModelProtocol {
    @Published var selectedLanguage: String
    @Published var currentUser: UserInfo?

    var appVersion: String { Bundle.main.versionNumber }
    var buildNumber: String { Bundle.main.buildNumber }
    var availableLanguages: [Language] { localizationManager.availableLanguages }

    private var localizationManager: any LocalizationManagerProtocol

    init(localizationManager: any LocalizationManagerProtocol) {
        self.localizationManager = localizationManager
        self.selectedLanguage = localizationManager.currentLanguage

        refreshUserData()

        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.currentUser = UserInfo(name: user.displayName ?? "",
                                             email: user.email ?? "")
            } else {
                self?.currentUser = nil
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
        } catch let error {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }
    
    func updateProfileName(_ name: String) {
        guard let user = Auth.auth().currentUser else { return }

        self.currentUser = UserInfo(name: name,
                                    email: user.email ?? "")
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                AppLogger.shared.error("Failed to update profile name: \(error.localizedDescription)", category: .auth)
            } else {
                AppLogger.shared.info("Profile name updated successfully", category: .auth)
                self?.refreshUserData()
            }
        }
    }

    func refreshUserData() {
        if let user = Auth.auth().currentUser {
            self.currentUser = UserInfo(name: user.displayName ?? "",
                                        email: user.email ?? "")
        }
    }

    func updateLanguage(_ languageId: String) {
        localizationManager.currentLanguage = languageId
        selectedLanguage = languageId
    }
}
