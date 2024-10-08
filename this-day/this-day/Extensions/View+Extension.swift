//
//  View+Extension.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

extension View {
    func showError(message: String, action: @escaping VoidClosure) -> some View {
        ErrorView(message: message, retryAction: action)
    }

    func showLoading(message: String = LocalizedString("message.loading.default")) -> some View {
        LoadingView(message: message)
    }

    func showPlaceholder(message: String) -> some View {
        PlaceholderView(message: message)
    }
}
