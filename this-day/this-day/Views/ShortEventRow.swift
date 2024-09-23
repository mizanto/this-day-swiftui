//
//  ShortEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import SwiftUI

struct ShortEventRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .padding(8)
    }
}

#Preview {
    ShortEventRow(text: "Hello, World!")
}
