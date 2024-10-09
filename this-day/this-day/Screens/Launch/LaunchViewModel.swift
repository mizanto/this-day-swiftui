//
//  LaunchViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import Foundation
import Combine

protocol LaunchViewModelProtocol: ObservableObject {
    func onAppear()
}

final class LaunchViewModel: LaunchViewModelProtocol {

    private let remoteConfigService: RemoteConfigServiceProtocol
    private let completion: (Result<RemoteSettings, Never>) -> Void

    private var cancellables: Set<AnyCancellable> = []

    init(remoteConfigService: RemoteConfigServiceProtocol,
         completion: @escaping (Result<RemoteSettings, Never>) -> Void) {
        self.remoteConfigService = remoteConfigService
        self.completion = completion
    }

    func onAppear() {
        remoteConfigService.fetchRemoteSettings()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.completion(.success(settings))
            }
            .store(in: &cancellables)
    }
}
