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
                self.view = AnyView(
                    LaunchViewBuilder.build() { [weak self] in
                        guard let self else { return }
                        self.authService.currentUserPublisher
                            .flatMap { user -> AnyPublisher<Bool, RepositoryError> in
                                guard user != nil else {
                                    return Just(false)
                                        .setFailureType(to: RepositoryError.self)
                                        .eraseToAnyPublisher()
                                }
                                return self.dataRepository.syncBookmarks()
                                    .map { _ in true }
                                    .eraseToAnyPublisher()
                            }
                            .receive(on: DispatchQueue.main)
                            .sink(
                                receiveCompletion: { [weak self] completion in
                                    guard let self else { return }
                                    if case .failure(let error) = completion {
                                        AppLogger.shared.error("[Coordinator]: Sync failed: \(error)", category: .coordinator)
                                        self.flow = .main
                                    }
                                },
                                receiveValue: { [weak self] isAuthenticated in
                                    guard let self else { return }
                                    if isAuthenticated {
                                        AppLogger.shared.info("[Coordinator]: Sync completed", category: .coordinator)
                                        self.flow = .main
                                    } else {
                                        AppLogger.shared.info("[Coordinator]: User is not authenticated", category: .coordinator)
                                        self.flow = .authorization
                                    }
                                }
                            )
                            .store(in: &self.cancellables)
                    }
                )

            case .authorization:
                AppLogger.shared.info("[Coordinator]: Start authorization", category: .coordinator)
                self.view = AnyView(
                    AuthViewBuilder.build(
                        authService: self.authService,
                        onAuthenticated: { [weak self] in
                            guard let self else { return }
                            self.dataRepository.syncBookmarks()
                                .receive(on: DispatchQueue.main)
                                .sink(
                                    receiveCompletion: { [weak self] completion in
                                        guard let self else { return }
                                        if case .failure(let error) = completion {
                                            AppLogger.shared.error("[Coordinator]: Sync failed: \(error)", category: .coordinator)
                                            self.flow = .main
                                        }
                                    },
                                    receiveValue: { [weak self] _ in
                                        guard let self else { return }
                                        AppLogger.shared.info("[Coordinator]: Sync completed", category: .coordinator)
                                        self.flow = .main
                                    }
                                )
                                .store(in: &self.cancellables)
                        }
                    )
                )
            case .main:
                AppLogger.shared.info("[Coordinator]: Start main flow", category: .coordinator)
                self.view = AnyView(
                    MainTabView(
                        authService: authService,
                        dataRepository: dataRepository,
                        completion: { [weak self] in
                            guard let self else { return }
                            self.dataRepository.clearLocalStorage()
                                .sink(
                                    receiveCompletion: { completion in
                                        if case .failure = completion {
                                            AppLogger.shared.error("[Coordinator]: Failed to clear local storage", category: .coordinator)
                                        }
                                    },
                                    receiveValue: { _ in
                                        AppLogger.shared.info("[Coordinator]: Cleared local storage", category: .coordinator)
                                        self.flow = .authorization
                                    }
                                )
                                .store(in: &self.cancellables)
                        }
                    )
                    .environmentObject(self.localizationManager)
                    .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                        self.localizationManager.objectWillChange.send()
                    }
                )
            }
        }
        .store(in: &cancellables)
    }
}
