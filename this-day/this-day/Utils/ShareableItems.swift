//
//  ShareableItems.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import Foundation

struct ShareableItems: Identifiable {
    let id = UUID()
    let items: [Any]
}
