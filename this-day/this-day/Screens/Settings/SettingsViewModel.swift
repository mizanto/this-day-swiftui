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
    var language: String { get }
}

final class SettingsViewModel: SettingsViewModelProtocol {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    var language: String = "English"
}
