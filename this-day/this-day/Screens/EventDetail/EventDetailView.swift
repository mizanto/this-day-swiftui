//
//  EventDetailView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.text)
                    .font(.body)
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)

                Text("Links:")
                    .font(.headline)
                    .padding(.horizontal)
            }
            .padding(.top)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(event.links) { link in
                    NavigationLink(
                        destination: ArticleViewBuilder.build(topic: link.title)
                    ) {
                        Text(link.title)
                            .font(.body)
                            .underline()
                            .foregroundColor(.blue)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                    Divider()
                        .padding(.horizontal)
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
    EventDetailView(event: Event(
        year: "81",
        text: "Domitian became Emperor of the Roman Empire upon the death of his brother Titus.",
        links: [
            EventLink(title: "Domitian", link: "https://wikipedia.org/wiki/Domitian"),
            EventLink(title: "Roman Empire", link: "https://wikipedia.org/wiki/Roman_Empire"),
            EventLink(title: "Titus", link: "https://wikipedia.org/wiki/Titus")
        ]
    ))
}
