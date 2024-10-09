//
//  LaunchViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import Foundation
import SwiftUI

final class LaunchViewBuilder {
    static func build(remoteConfigService: RemoteConfigServiceProtocol,
                      completion: @escaping (Result<RemoteSettings, Never>) -> Void) -> some View {
        let viewModel = LaunchViewModel(remoteConfigService: remoteConfigService,
                                        completion: completion)
        return LaunchView(viewModel: viewModel)
    }
}
