//
//  ThisDayApp.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

@main
struct ThisDayApp: App {
    let networkService = NetworkService()

    var body: some Scene {
        WindowGroup {
            EventsViewBuilder.build(networkService: NetworkService())
        }
    }
}
