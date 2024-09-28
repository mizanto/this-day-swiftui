//
//  Bundle+Extrnsion.swift
//  this-day
//
//  Created by Sergey Bendak on 28.09.2024.
//

import Foundation

extension Bundle {
    var versionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
