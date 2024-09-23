//
//  TimelineRow.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct TimelineRow: View {
    let event: Event

    var body: some View {
        HStack(alignment: .top) {
            Text(event.year ?? "")
                .font(.headline)
                .frame(width: 54, alignment: .trailing)

            VStack(alignment: .leading, spacing: 0) {
                if let title = event.title, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 4)
                }

                if let subtitle = event.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

#Preview {
    TimelineRow(event: Event(from: .init(year: "1998", title: "Text", additional: "Addiitonal")))
}
