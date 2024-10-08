//
//  BookmarkDataModel.swift
//  this-day
//
//  Created by Sergey Bendak on 4.10.2024.
//

import Foundation

struct BookmarkDataModel: Codable {
    let id: String
    let eventID: String
    let dateAdded: Date
}
