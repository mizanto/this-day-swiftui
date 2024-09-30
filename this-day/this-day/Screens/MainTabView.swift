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

    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView {
            DayViewBuilder.build(networkService: networkService,
                                 storageService: storageService,
                                 localizationManager: localizationManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(NSLocalizedString("tab_title.events", comment: ""))
                }
                .tag(0)

            BookmarksViewBuilder.build(storageService: storageService,
                                       localizationManager: localizationManager)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text(NSLocalizedString("tab_title.bookmarks", comment: ""))
                }
                .tag(1)

            SettingsViewBuilder.build(localizationManager: localizationManager)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text(NSLocalizedString("tab_title.settings", comment: ""))
                }
                .tag(2)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { _ in
                selectedTab = selectedTab
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .languageDidChange, object: nil)
        }
    }
}
