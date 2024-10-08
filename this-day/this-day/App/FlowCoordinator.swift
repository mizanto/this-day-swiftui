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
    }

    @Published var flow: Flow = .idle

    var view: AnyView!

    private let dataRepository: DataRepositoryProtocol
    private let authService: AuthenticationServiceProtocol
    private let localizationManager: LocalizationManager

    private var cancellables: Set<AnyCancellable> = []

    init(dataRepository: DataRepositoryProtocol,
         authService: AuthenticationServiceProtocol,
         localizationManager: LocalizationManager) {
        self.dataRepository = dataRepository
        self.authService = authService
        self.localizationManager = localizationManager
    }

    func start() {
        $flow.removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    AppLogger.shared.info("[Coordinator]: Idle application", category: .coordinator)
                    self.flow = .launching
                case .launching:
                    AppLogger.shared.info("[Coordinator]: Launching application", category: .coordinator)
                    self.view = AnyView(LaunchViewBuilder.build(completion: self.handleLaunchCompletion))
                case .authorization:
                    AppLogger.shared.info("[Coordinator]: Start authorization", category: .coordinator)
                    self.view = AnyView(AuthViewBuilder.build(authService: self.authService,
                                                              onAuthenticated: self.handleAuthentication))
                case .main:
                    AppLogger.shared.info("[Coordinator]: Start main flow", category: .coordinator)
                    self.view = AnyView(
                        MainTabView(authService: self.authService,
                                    dataRepository: self.dataRepository,
                                    completion: self.handleMainCompletion)
                        .environmentObject(self.localizationManager)
                        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                            self.localizationManager.objectWillChange.send()
                        }
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func handleLaunchCompletion() {
        authService.currentUserPublisher
            .first()
            .flatMap { user -> AnyPublisher<Flow, Never> in
                if user != nil {
                    return self.synchronizeBookmarks()
                } else {
                    return Just(.authorization).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$flow)
    }

    private func handleAuthentication() {
        synchronizeBookmarks()
            .receive(on: DispatchQueue.main)
            .assign(to: &$flow)
    }

    private func handleMainCompletion() {
        dataRepository.clearLocalStorage()
            .receive(on: DispatchQueue.main)
            .map { _ in Flow.authorization }
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
