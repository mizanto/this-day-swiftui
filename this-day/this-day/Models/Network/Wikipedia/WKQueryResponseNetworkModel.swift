//
//  WKQueryResponseNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation

struct WKQueryResponseNetworkModel: Codable {
    let pages: [String: WKPageNetworkModel]
}
