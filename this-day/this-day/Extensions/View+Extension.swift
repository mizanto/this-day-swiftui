//
//  View+Extension.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

extension View {
    func showError(message: String, action: @escaping () -> Void) -> some View {
        ErrorView(message: message, retryAction: action)
    }

    func showLoading(message: String) -> some View {
        LoadingView(message: message)
    }
}
