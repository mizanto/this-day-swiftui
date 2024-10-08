//
//  LaunchViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import Foundation
import SwiftUI

final class LaunchViewBuilder {
    static func build(completion: @escaping VoidClosure) -> some View {
        let viewModel = LaunchViewModel(completion: completion)
        return LaunchView(viewModel: viewModel)
    }
}
