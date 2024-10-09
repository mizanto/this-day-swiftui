//
//  AnalyticsService.swift
//  this-day
//
//  Created by Sergey Bendak on 9.10.2024.
//

import Foundation
import FirebaseAnalytics

protocol AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsService.Event)
    func logEvent(_ event: AnalyticsService.Event, parameters: [String: Any])
    func setUserProperty(_ property: AnalyticsService.UserProperty, value: String)
    func setUserId(_ id: String)
}

class AnalyticsService: AnalyticsServiceProtocol {
    enum Event: String {
        case login
        case signup = "sign_up"
        case signout = "sign_out"
        case tabSelected = "tab_selected"
        case categorySelected = "category_selected"
        case addBookmark = "add_bookmark"
        case removeBookmark = "remove_bookmark"
        case copyEvent = "copy_event"
        case shareEvent = "share_event"
        case languageSelected = "language_selected"
    }

    enum UserProperty: String {
        case language
    }

    static let shared = AnalyticsService()

    private init() {}

    func logEvent(_ event: Event) {
        logEvent(event.rawValue)
    }

    func logEvent(_ event: Event, parameters: [String: Any]) {
        logEvent(event.rawValue, parameters: parameters)
    }

    func setUserProperty(_ property: UserProperty, value: String) {
        setUserProperty(property.rawValue, value: value)
    }

    func setUserId(_ id: String) {
        Analytics.setUserID(id)
    }

    private func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    private func setUserProperty(_ name: String, value: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
