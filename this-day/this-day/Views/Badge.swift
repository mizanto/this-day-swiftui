//
//  Badge.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//

import SwiftUI

struct Badge: View {
    let title: String
    let color: Color

    init(title: String, color: Color) {
        self.title = title
        self.color = color
    }

    init(category: EventCategory) {
        self.title = category.string
        self.color = category.color
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 1)
            .padding(.horizontal, 6)
            .background(color)
            .cornerRadius(2)
    }
}
