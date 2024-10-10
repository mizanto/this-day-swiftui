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
    /// App Store page URL
    var appStorePageURL: String { get }
    /// Returns true if current version less than `minVersion`
    var isCurrentVersionLessThanMinVersion: Bool { get }
    /// Returns true if current version less than `appStoreVersion`
    var isUpdateAvailable: Bool { get }
}

final class AppSettings: AppSettingsProtocol, ObservableObject {
    private enum SettingsKey: String {
        case minVersion = "min_version"
        case currentVersion = "current_version"
        case language = "language"
        case appStoreURL = "app_store_url"
    }

    private enum DefaultValue {
        static let minVersion: String = "1.0.0"
        static let currentVersion: String = "1.0.0"
        static let language: String = "en"
        static let appStoreURL: String = "https://apps.apple.com"
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

    var appStorePageURL: String {
        get { getString(forKey: .appStoreURL) ?? DefaultValue.appStoreURL }
        set { saveString(value: newValue, forKey: .appStoreURL) }
    }

    var isCurrentVersionLessThanMinVersion: Bool { appVersion.isVersionLessThan(minVersion) }
    var isUpdateAvailable: Bool { appVersion.isVersionLessThan(appStoreVersion) }

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
