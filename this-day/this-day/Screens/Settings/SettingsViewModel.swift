//
//  SettingsViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import Foundation

protocol SettingsViewModelProtocol: ObservableObject {
    var appVersion: String { get }
    var buildNumber: String { get }
    var availableLanguages: [Language] { get }
    var selectedLanguage: String { get set }
    func updateLanguage(_ languageId: String)
}

final class SettingsViewModel: SettingsViewModelProtocol {
    @Published var selectedLanguage: String
    private var localizationManager: LocalizationManager

    var appVersion: String { Bundle.main.versionNumber }
    var buildNumber: String { Bundle.main.buildNumber }
    var availableLanguages: [Language] { localizationManager.availableLanguages }

    init(localizationManager: LocalizationManager = .shared) {
        self.localizationManager = localizationManager
        self.selectedLanguage = localizationManager.currentLanguage
    }

    func updateLanguage(_ languageId: String) {
        localizationManager.currentLanguage = languageId
        selectedLanguage = languageId
    }
}
