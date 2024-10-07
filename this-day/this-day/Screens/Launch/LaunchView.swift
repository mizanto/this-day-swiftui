//
//  LaunchView.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import SwiftUI

struct LaunchView<ViewModel: LaunchViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
        showLoading(message: "Launching...")
            .onAppear {
                viewModel.onAppear()
            }
    }
}
