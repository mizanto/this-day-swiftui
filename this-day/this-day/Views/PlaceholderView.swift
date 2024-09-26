//
//  PlaceholderView.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//

import SwiftUI

struct PlaceholderView: View {
    let message: String

    var body: some View {
        VStack {
            Image(systemName: "info.circle")
                .font(.system(size: 64, weight: .thin))
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical)
        }
    }
}

#Preview {
    PlaceholderView(message: "Some long long long long long long placeholder message")
}
