//
//  ShortEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import SwiftUI

struct ShortEventRow: View {
    let event: ShortEvent

    var body: some View {
        Text(event.title)
            .font(.body)
            .padding(8)
    }
}

#Preview {
    ShortEventRow(event: ShortEvent(title: "Hello, World!"))
}
