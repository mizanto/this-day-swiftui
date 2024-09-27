//
//  Snackbar.swift
//  this-day
//
//  Created by Sergey Bendak on 27.09.2024.
//

import SwiftUI

struct Snackbar: View {
    var message: String

    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.black.opacity(0.7))
            .cornerRadius(16)
            .shadow(radius: 4)
    }
}
