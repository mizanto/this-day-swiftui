//
//  ErrorView.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64, weight: .thin))
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical)
            if let retryAction {
                Button(
                    action: retryAction,
                    label: {
                        Text(LocalizedString("error.retry"))
                            .font(.headline)
                            .padding(12)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                )
            }
        }
    }
}

#Preview {
    ErrorView(message: "Some long long long long long long error message", retryAction: {})
}
