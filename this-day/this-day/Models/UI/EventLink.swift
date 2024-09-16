//
//  EventLink.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct EventLink: Identifiable {
    let id = UUID()
    let title: String
    let link: String
}
