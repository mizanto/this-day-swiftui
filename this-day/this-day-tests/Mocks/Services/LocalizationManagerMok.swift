//
//  LocalizationManagerMok.swift
//  this-day
//
//  Created by Sergey Bendak on 30.09.2024.
//

import Foundation

@testable import this_day

class LocalizationManagerMock: LocalizationManagerProtocol {

    let availableLanguages = [
        Language(id: "en", name: "English"),
        Language(id: "ru", name: "Русский")
    ]
    
    @Published var currentLanguage: String
    
    init(initialLanguage: String = "en") {
        self.currentLanguage = initialLanguage
    }
}
