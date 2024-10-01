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
                    AuthViewBuilder.build {
                        showingAuthView = false
                        viewModel.refreshUserData()
                    }
                }
        }
    }

    @ViewBuilder
    private func content() -> some View {
        Form {
            Section(header: Text("Profile")) {
                if let user = viewModel.currentUser {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(user.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("E-mail")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                    Button(
                        action: {
                            viewModel.signOut()
                        },
                        label: {
                            Text("Sign out")
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
                            Text("Sign in")
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.blue)
                        }
                    )
                }
            }
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
    SettingsView(viewModel: SettingsViewModel(localizationManager: LocalizationManager()))
}
