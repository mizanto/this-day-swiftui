//
//  SettingsView.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(LocalizedString("tab_title.settings"))
        }
    }

    @ViewBuilder
    private func content() -> some View {
        Form {
            Section(header: Text(LocalizedString("settings.section.general"))) {
                HStack {
                    Text(LocalizedString("settings.language"))
                    Spacer()
                    Text(viewModel.language)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text(LocalizedString("settings.section.app_info"))) {
                HStack {
                    Text(LocalizedString("settings.version"))
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedString("settings.build"))
                    Spacer()
                    Text(viewModel.buildNumber)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
