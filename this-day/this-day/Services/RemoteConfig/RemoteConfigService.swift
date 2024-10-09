//
//  RemoteConfigService.swift
//  this-day
//
//  Created by Sergey Bendak on 9.10.2024.
//

import FirebaseRemoteConfigInternal
import Combine

protocol RemoteConfigServiceProtocol {
    func fetchRemoteSettings() -> AnyPublisher<RemoteSettings, Never>
}

final class RemoteConfigService: RemoteConfigServiceProtocol {

    enum ConfigKey: String {
        case minVersion = "min_version"
        case currentVersion = "current_version"
        case storeURL = "store_url"
    }

    static let shared = RemoteConfigService()

    private var remoteConfig: RemoteConfig

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        let defaultValues: [String: NSObject] = [
            ConfigKey.minVersion.rawValue: "1.0.0" as NSObject,
            ConfigKey.currentVersion.rawValue: "1.0.0" as NSObject,
            ConfigKey.storeURL.rawValue: "https://apps.apple.com" as NSObject
        ]
        remoteConfig.setDefaults(defaultValues)
    }

    func fetchRemoteSettings() -> AnyPublisher<RemoteSettings, Never> {
        Future { promise in
            self.remoteConfig.fetch(withExpirationDuration: 0) { [weak self] status, error in
                guard let self else { return }
                if status == .success {
                    self.remoteConfig.activate { _, _ in
                        AppLogger.shared.debug("[Remote Config]: Successfully activated")
                    }
                } else {
                    if let error = error {
                        AppLogger.shared.error("[Remote Config]: Error fetching remote config: \(error)")
                    }
                }
                let settings = RemoteSettings(
                    minVersion: self.getString(forKey: .minVersion),
                    currentVersion: self.getString(forKey: .currentVersion),
                    storeURL: self.getString(forKey: .storeURL)
                )
                promise(.success(settings))
            }
        }
        .eraseToAnyPublisher()
    }

    private func getValue(forKey key: ConfigKey) -> RemoteConfigValue {
        return remoteConfig[key.rawValue]
    }

    private func getString(forKey key: ConfigKey) -> String {
        return getValue(forKey: key).stringValue
    }

    private func getBool(forKey key: ConfigKey) -> Bool {
        return getValue(forKey: key).boolValue
    }

    private func getInt(forKey key: ConfigKey) -> Int {
        return getValue(forKey: key).numberValue.intValue
    }
}
