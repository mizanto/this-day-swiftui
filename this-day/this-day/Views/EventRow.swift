//
//  EventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct EventRow: View {
    let event: Event

    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)

                if !event.text.isEmpty {
                    Text(event.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 8)
        }
}

#Preview {
    EventRow(event: Event(from: .init(title: "Title", text: "Text")))
}
