//
//  SettingsView.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var showingAuthView = false

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(LocalizedString("tab_title.settings"))
                .sheet(isPresented: $showingAuthView) {
                    viewModel.makeAuthView {
                        showingAuthView = false
                    }
                }
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
            if let user = viewModel.currentUser {
                HStack {
                    Text(LocalizedString("settings.name"))
                    Spacer()
                    Text(user.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(LocalizedString("settings.email"))
                    Spacer()
                    Text(user.email)
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
            } else {
                Button(
                    action: {
                        showingAuthView = true
                    },
                    label: {
                        Text(LocalizedString("auth.button.sign_in"))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.blue)
                    }
                )
            }
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
            localizationManager: LocalizationManager()
        )
    )
}
