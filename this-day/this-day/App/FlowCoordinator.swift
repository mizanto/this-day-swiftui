//
//  FlowCoordinator.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import Combine
import SwiftUI

final class FlowCoordinator: ObservableObject {
    enum Flow {
        case idle
        case launching
        case authorization
        case main
        case error
    }

    @Published var flow: Flow = .idle

    var view: AnyView!

    private let dataRepository: DataRepositoryProtocol
    private let authService: AuthenticationServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let remoteConfigService: RemoteConfigServiceProtocol
    private var settings: AppSettings

    private var cancellables: Set<AnyCancellable> = []

    init(dataRepository: DataRepositoryProtocol,
         authService: AuthenticationServiceProtocol,
         analyticsService: AnalyticsServiceProtocol) {
        self.settings = AppSettings.shared
        self.dataRepository = dataRepository
        self.authService = authService
        self.analyticsService = analyticsService
        self.remoteConfigService = RemoteConfigService.shared
    }

    func start() {
        Bundle.setLanguage(settings.language)

        $flow.removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    AppLogger.shared.info("[Coordinator]: Idle application", category: .coordinator)
                    self.flow = .launching
                case .launching:
                    AppLogger.shared.info("[Coordinator]: Launching application", category: .coordinator)
                    self.view = AnyView(LaunchViewBuilder.build(remoteConfigService: remoteConfigService,
                                                                completion: self.handleLaunchCompletion))
                case .authorization:
                    AppLogger.shared.info("[Coordinator]: Start authorization", category: .coordinator)
                    self.view = AnyView(AuthViewBuilder.build(authService: self.authService,
                                                              analyticsService: self.analyticsService,
                                                              onAuthenticated: self.handleAuthentication))
                case .main:
                    AppLogger.shared.info("[Coordinator]: Start main flow", category: .coordinator)
                    self.view = AnyView(
                        MainTabView(authService: self.authService,
                                    dataRepository: self.dataRepository,
                                    analyticsService: self.analyticsService,
                                    completion: self.handleMainCompletion)
                        .environmentObject(self.settings)
                        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                            self.settings.objectWillChange.send()
                        }
                    )
                case .error:
                    AppLogger.shared.error("[Coordinator]: Showing error", category: .coordinator)
                    self.view = AnyView(
                        ErrorView(
                            message: LocalizedString("message.hard_update"),
                            buttonTitle: LocalizedString("button.update"),
                            retryAction: { [unowned self] in
                                guard let url = URL(string: self.settings.appStorePageURL) else { return }
                                UIApplication.shared.open(url)
                            }
                        )
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func handleLaunchCompletion(settings: Result<RemoteSettings, Never>) {
        if case .success(let settings) = settings {
            AppLogger.shared.debug("[Coordinator]: Remote settings loaded successfully: \(settings)")
            self.settings.appStoreVersion = settings.currentVersion
            self.settings.minVersion = settings.minVersion
            self.settings.appStorePageURL = settings.storeURL
        }

        if self.settings.isCurrentVersionLessThanMinVersion {
            self.flow = .error
        } else {
            authService.currentUserPublisher
                .first()
                .flatMap { user -> AnyPublisher<Flow, Never> in
                    if let user {
                        self.analyticsService.setUserId(user.id)
                        self.analyticsService.setUserProperty(.language, value: self.settings.language)
                        return self.synchronizeBookmarks()
                    } else {
                        return Just(.authorization).eraseToAnyPublisher()
                    }
                }
                .receive(on: DispatchQueue.main)
                .assign(to: &$flow)
        }
    }

    private func handleAuthentication() {
        synchronizeBookmarks()
            .receive(on: DispatchQueue.main)
            .assign(to: &$flow)
    }

    private func handleMainCompletion() {
        dataRepository.clearLocalStorage()
            .receive(on: DispatchQueue.main)
            .map { _ in
                self.view = AnyView(EmptyView())
                return Flow.authorization
            }
            .catch { _ in Just(.main) }
            .assign(to: &$flow)
    }

    private func synchronizeBookmarks() -> AnyPublisher<Flow, Never> {
        dataRepository.syncBookmarks()
            .map { _ in Flow.main }
            .catch { error -> Just<Flow> in
                AppLogger.shared.error("[Coordinator]: Sync failed: \(error)", category: .coordinator)
                return Just(.main)
            }
            .eraseToAnyPublisher()
    }
}
