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
                .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func content() -> some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Text("Language")
                    Spacer()
                    Text(viewModel.language)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("App Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
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
