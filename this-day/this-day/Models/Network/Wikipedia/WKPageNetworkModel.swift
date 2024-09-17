//
//  WKPageNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation

struct WKPageNetworkModel: Codable {
    let pageid: Int
    let title: String
    let extract: String? // Optional, used for full article text
    let thumbnail: WKThumbnailNetworkModel? // Optional, used for article image
}
