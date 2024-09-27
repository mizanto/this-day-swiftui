//
//  SettingsViewBuilder.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

final class SettingsViewBuilder {
    static func build() -> some View {
        let viewModel = SettingsViewModel()
        return SettingsView(viewModel: viewModel)
    }
}
