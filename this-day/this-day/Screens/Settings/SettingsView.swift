//
//  SettingsView.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var isPresentingPrivacyPolicy = false

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(LocalizedString("tab_title.settings"))
        }
        .snackbar(isPresented: $viewModel.showSnackbar, message: viewModel.appVersionMessage)
        .sheet(isPresented: $isPresentingPrivacyPolicy) {
            PrivacyPolicyView(language: viewModel.selectedLanguage)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        Form {
            profileSection()
            generalSection()
            legalInfoSection()
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
                        .bold()
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.appRed)
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
            .colorMultiply(.appBlue)
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
                    .onLongPressGesture {
                        viewModel.copyAppVersion()
                    }
            }
            if viewModel.isUpdateAvailable {
                HStack {
                    Text(LocalizedString("settings.update_available"))
                    Spacer()
                    Button(
                        action: {
                            viewModel.updateApplication()
                        },
                        label: {
                            Text(LocalizedString("button.update"))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .foregroundColor(.white)
                                .background(.appRed)
                                .cornerRadius(4)
                        }
                    )
                }
            }
        }
    }

    private func legalInfoSection() -> some View {
        Section(header: Text(LocalizedString("settings.section.legal_info"))) {
            Button(action: {
                isPresentingPrivacyPolicy = true
            }) {
                HStack {
                    Text(LocalizedString("settings.section.legal_info.privacy_policy"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .colorMultiply(.appBlue)
        }
    }

    private func profileFooterView() -> some View {
        Text(LocalizedString("settings.section.profile.footer"))
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            settings: AppSettings.shared,
            authService: AuthenticationService(),
            analyticsService: AnalyticsService.shared,
            onLogout: {}
        )
    )
}
