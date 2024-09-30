//
//  LocalizationManager.swift
//  this-day
//
//  Created by Sergey Bendak on 28.09.2024.
//

import Foundation

struct Language: Identifiable {
    let id: String
    let name: String
}

protocol LocalizationManagerProtocol: ObservableObject {
    var availableLanguages: [Language] { get }
    var currentLanguage: String { get set }
}

class LocalizationManager: LocalizationManagerProtocol {

    let availableLanguages = [
        Language(id: "en", name: "English"),
        Language(id: "ru", name: "Русский")
    ]

    @Published var currentLanguage: String = Locale.current.language.languageCode?.identifier ?? "en" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            UserDefaults.standard.synchronize()
            Bundle.setLanguage(currentLanguage)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = savedLanguage
            Bundle.setLanguage(savedLanguage)
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
