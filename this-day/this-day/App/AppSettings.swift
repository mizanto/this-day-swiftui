//
//  AppSettings.swift
//  this-day
//
//  Created by Sergey Bendak on 9.10.2024.
//

import Foundation

protocol AppSettingsProtocol {
    /// Min supprted app version
    var minVersion: String { get set }
    /// Available App Store version
    var appStoreVersion: String { get set }
    /// Selected langusge
    var language: String { get set }
    /// Current app version
    var appVersion: String { get }
    /// Build number
    var buildNumber: String { get }
}

final class AppSettings: AppSettingsProtocol, ObservableObject {
    private enum SettingsKey: String {
        case minVersion = "min_version"
        case currentVersion = "current_version"
        case language = "language"
    }

    private enum DefaultValue {
        static let minVersion: String = "1.0.0"
        static let currentVersion: String = "1.0.0"
        static let language: String = "en"
    }

    static let shared = AppSettings()

    var minVersion: String {
        get { getString(forKey: .minVersion) ?? DefaultValue.minVersion }
        set { saveString(value: newValue, forKey: .minVersion) }
    }

    var appStoreVersion: String {
        get { getString(forKey: .currentVersion) ?? DefaultValue.currentVersion }
        set { saveString(value: newValue, forKey: .currentVersion) }
    }

    var language: String {
        get { getString(forKey: .language) ?? DefaultValue.language }
        set { saveString(value: newValue, forKey: .language) }
    }

    var appVersion: String { Bundle.main.versionNumber }
    var buildNumber: String { Bundle.main.buildNumber }

    private let userDefaults: UserDefaults = .standard
    
    private func saveString(value: String, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    private func saveBool(value: Bool, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    private func getString(forKey key: SettingsKey) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }

    private func getBool(forKey key: SettingsKey) -> Bool {
        return userDefaults.bool(forKey: key.rawValue)
    }
}
