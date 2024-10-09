//
//  Snackbar.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct Snackbar: View {
    enum SnackbarType {
        case success
        case error
        case message
    }

    var message: String
    var type: SnackbarType

    var body: some View {
        Text(message)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(radius: 4)
    }

    private var backgroundColor: Color {
        switch type {
        case .success: return .appGreen.opacity(0.9)
        case .error: return .appRed.opacity(0.9)
        case .message: return .main.opacity(0.7)
        }
    }

    private var foregroundColor: Color {
        switch type {
        case .success: return .white
        case .error: return .white
        case .message: return .white
        }
    }
}
