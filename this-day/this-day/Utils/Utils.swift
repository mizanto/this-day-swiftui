//
//  Utils.swift
//  this-day
//
//  Created by Sergey Bendak on 28.09.2024.
//

import Foundation

// swiftlint:disable identifier_name
typealias VoidClosure = () -> Void

public func LocalizedString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
