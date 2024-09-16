//
//  EventDetailView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct EventDetailView: View {
    var event: HistoricalEvent

    var body: some View {
        VStack(alignment: .leading) {
            Text(event.text)
                .font(.body)
                .padding(.horizontal)
                .padding(.vertical)

            Text("Links:")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(event.links) { link in
                    // TODO: add NavigationLink
                    Text(link.title)
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding()
                    Divider()
                }
            }
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle(event.year)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EventDetailView(event: HistoricalEvent(
        year: "81",
        text: "Domitian became Emperor of the Roman Empire upon the death of his brother Titus.",
        links: [
            EventLink(title: "Domitian", link: "https://wikipedia.org/wiki/Domitian"),
            EventLink(title: "Roman Empire", link: "https://wikipedia.org/wiki/Roman_Empire"),
            EventLink(title: "Titus", link: "https://wikipedia.org/wiki/Titus")
        ]
    ))
}
