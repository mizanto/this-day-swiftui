//
//  MainTabView.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct MainTabView: View {
    let networkService: NetworkServiceProtocol
    let storageService: StorageServiceProtocol

    var body: some View {
        TabView {
            DayViewBuilder.build(networkService: networkService, storageService: storageService)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }

            BookmarksViewBuilder.build(storageService: storageService)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("Bookmarks")
                }
        }
    }
}
