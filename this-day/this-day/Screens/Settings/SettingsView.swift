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
            profileSection()
            generalSection()
            appInfoSection()
        }
    }

    private func profileSection() -> some View {
        Section(header: Text(LocalizedString("settings.section.profile")),
                footer: !viewModel.isAuthenticated ? profileFooterView() : nil) {
            HStack {
                Text(LocalizedString("settings.name"))
                Spacer()
                Text(viewModel.currentUser?.name ?? "???")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text(LocalizedString("settings.email"))
                Spacer()
                Text(viewModel.currentUser?.email ?? "???")
                    .foregroundColor(.secondary)
            }
            Button(
                action: {
                    viewModel.signOut()
                },
                label: {
                    Text(LocalizedString("auth.button.sign_out"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                }
            )
        }
    }

    private func generalSection() -> some View {
        Section(header: Text(LocalizedString("settings.section.general"))) {
            Picker(LocalizedString("settings.language"), selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.availableLanguages) { language in
                    Text(language.name).tag(language.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.selectedLanguage) { _, newLanguage in
                viewModel.updateLanguage(newLanguage)
            }
        }
    }

    private func appInfoSection() -> some View {
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

    private func profileFooterView() -> some View {
        Text(LocalizedString("settings.section.profile.footer"))
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            authService: AuthenticationService(),
            localizationManager: LocalizationManager(),
            onLogout: {}
        )
    )
}
