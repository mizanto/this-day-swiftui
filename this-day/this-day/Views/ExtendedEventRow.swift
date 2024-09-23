//
//  ExtendedEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct ExtendedEventRow: View {
    let event: ExtendedEvent

    var body: some View {
        HStack(alignment: .top) {
            Text(event.year)
                .font(.headline)
                .frame(width: 54, alignment: .trailing)

            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 4)

                Text(event.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

#Preview {
    ExtendedEventRow(event: ExtendedEvent(year: "1998", title: "Text", subtitle: "Subtitle"))
}
