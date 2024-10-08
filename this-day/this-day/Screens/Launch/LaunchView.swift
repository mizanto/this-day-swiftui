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
        ZStack {
            Color.white
            Image("logo_light")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.onAppear()
        }
    }
}
