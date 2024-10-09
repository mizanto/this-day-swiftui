//
//  MainTabView.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct MainTabView: View {
    let authService: AuthenticationServiceProtocol
    let dataRepository: DataRepositoryProtocol
    let analyticsService: AnalyticsServiceProtocol
    
    @EnvironmentObject var settings: AppSettings

    @State private var selectedTab: Int = 0

    let completion: VoidClosure

    init(authService: AuthenticationServiceProtocol,
         dataRepository: DataRepositoryProtocol,
         analyticsService: AnalyticsServiceProtocol,
         completion: @escaping VoidClosure) {
        self.authService = authService
        self.dataRepository = dataRepository
        self.analyticsService = analyticsService
        self.completion = completion
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DayViewBuilder.build(dataRepository: dataRepository,
                                 settings: settings,
                                 analyticsService: analyticsService)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(NSLocalizedString("tab_title.events", comment: ""))
                }
                .tag(0)

            BookmarksViewBuilder.build(dataRepository: dataRepository,
                                       settings: settings,
                                       analyticsService: analyticsService)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text(NSLocalizedString("tab_title.bookmarks", comment: ""))
                }
                .tag(1)

            SettingsViewBuilder.build(settings: settings,
                                      authService: authService,
                                      analyticsService: analyticsService,
                                      onLogout: completion)
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
        .onChange(of: selectedTab) { _, newTab in
            logTabSelection(newTab)
        }
    }

    private func logTabSelection(_ index: Int) {
        let tab: String
        switch index {
        case 0: tab = "events"
        case 1: tab = "bookmarks"
        case 2: tab = "settings"
        default: tab = "unknown"
        }
        analyticsService.logEvent(.tabSelected, parameters: ["title": tab])
    }
}
