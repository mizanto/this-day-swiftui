//
//  ThisDayApp.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

@main
struct ThisDayApp: App {

    init() {
        let historyService = HistoryService()
        let wikipediaService = WikipediaService()

        DIContainer.shared.register(historyService as HistoryServiceProtocol)
        DIContainer.shared.register(wikipediaService as WikipediaServiceProtocol)
    }

    var body: some Scene {
        WindowGroup {
            EventsViewBuilder.build()
        }
    }
}
