//
//  LaunchViewModel.swift
//  this-day
//
//  Created by Sergey Bendak on 7.10.2024.
//

import Combine

protocol LaunchViewModelProtocol: ObservableObject {
    func onAppear()
}

final class LaunchViewModel: LaunchViewModelProtocol {

    private let completion: VoidClosure

    init(completion: @escaping VoidClosure) {
        self.completion = completion
    }

    func onAppear() {
        completion()
    }
}
