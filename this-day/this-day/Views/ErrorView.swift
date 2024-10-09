//
//  ErrorView.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let buttonTitle: String?
    let retryAction: VoidClosure?

    init(
        message: String,
        buttonTitle: String? = nil,
        retryAction: VoidClosure? = nil
    ) {
        self.message = message
        self.buttonTitle = buttonTitle
        self.retryAction = retryAction
    }

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
                        titleForButton()
                            .font(.headline)
                            .padding(12)
                            .background(.main)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                )
            }
        }
    }

    func titleForButton() -> Text {
        if let buttonTitle {
            Text(buttonTitle)
        } else {
            Text(LocalizedString("error.retry"))
        }
    }
}

#Preview {
    ErrorView(message: "Some long long long long long long error message")
}
