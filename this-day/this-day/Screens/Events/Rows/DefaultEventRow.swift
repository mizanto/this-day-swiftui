//
//  DefaultEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import SwiftUI

struct DefaultEventRow: View {
    let event: DefaultEvent

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
            }
        }
    }
}

#Preview {
    DefaultEventRow(event: DefaultEvent(year: "1998", title: "Title"))
}
