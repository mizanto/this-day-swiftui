//
//  Event.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let text: String?
    let additionalInfo: String?

    init(from networkModel: EventNetworkModel) {
        self.title = networkModel.title
        self.text = networkModel.text
        self.additionalInfo = networkModel.additional
    }
}
