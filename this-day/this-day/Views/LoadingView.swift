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
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text(message)
                .font(.headline)
                .padding(8)
        }
    }
}

#Preview {
    LoadingView(message: "Loading...")
}
