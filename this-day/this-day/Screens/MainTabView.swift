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
                    Image(systemName: "list.bullet")
                    Text(NSLocalizedString("tab_title.events", comment: ""))
                }

            BookmarksViewBuilder.build(storageService: storageService)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text(NSLocalizedString("tab_title.bookmarks", comment: ""))
                }

            SettingsViewBuilder.build()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text(NSLocalizedString("tab_title.settings", comment: ""))
                }
        }
    }
}
