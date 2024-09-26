//
//  LoadingView.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack {
            Image(systemName: "infinity.circle")
                .font(.system(size: 64, weight: .thin))

            Text(message)
                .font(.title3)
                .padding(.vertical)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
}

#Preview {
    LoadingView(message: "Loading...")
}
