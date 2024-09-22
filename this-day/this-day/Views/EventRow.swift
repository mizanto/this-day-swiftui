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
            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.headline)
                    .padding(.bottom, 8)

                if let text = event.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 4)
                }

                if let additional = event.additionalInfo, !additional.isEmpty {
                    Text(additional)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 8)
        }
}

#Preview {
    EventRow(event: Event(from: .init(title: "Title", text: "Text", additional: "Addiitonal")))
}
