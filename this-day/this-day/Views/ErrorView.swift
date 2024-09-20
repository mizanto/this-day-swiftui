//
//  ErrorView.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack {
            Text(message)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical)
            Button(
                action: retryAction,
                label: {
                    Text("Try Again")
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

#Preview {
    ErrorView(message: "Some long long long long long long error message", retryAction: {})
}
