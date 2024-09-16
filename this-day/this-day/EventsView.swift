//
//  ContentView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct HistoricalEvent: Identifiable {
    let id = UUID()
    let year: String
    let text: String
    let links: [EventLink]
}

struct EventLink: Identifiable {
    let id = UUID()
    let title: String
    let link: String
}

let sampleEvents = [
    HistoricalEvent(
        year: "81",
        text: "Domitian became Emperor of the Roman Empire upon the death of his brother Titus.",
        links: [
            EventLink(title: "Domitian", link: "https://wikipedia.org/wiki/Domitian"),
            EventLink(title: "Roman Empire", link: "https://wikipedia.org/wiki/Roman_Empire"),
            EventLink(title: "Titus", link: "https://wikipedia.org/wiki/Titus")
        ]
    ),
    HistoricalEvent(
        year: "629",
        text: "Emperor Heraclius enters Constantinople in triumph after his victory over the Persian Empire.",
        links: [
            EventLink(title: "Heraclius", link: "https://wikipedia.org/wiki/Heraclius"),
            EventLink(title: "Constantinople", link: "https://wikipedia.org/wiki/Constantinople"),
            EventLink(title: "Sasanian Empire", link: "https://wikipedia.org/wiki/Sasanian_Empire")
        ]
    )
]

struct EventsView: View {
    var events: [HistoricalEvent] = sampleEvents
    var title: String = "September 14"

    var body: some View {
        NavigationView {
            List(events) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.year)
                            .font(.headline)
                        Text(event.text)
                            .font(.body)
                            .lineLimit(1)
                        HStack {
                            ForEach(event.links) { link in
                                Text(link.title)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    EventsView()
}
