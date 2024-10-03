//
//  BookmarkRow.swift
//  this-day
//
//  Created by Sergey Bendak on 26.09.2024.
//

import SwiftUI

struct BookmarkRow: View {
    let event: BookmarkEvent
    let onBookmarkPressed: (String) -> Void
    let onCopyPressed: (String) -> Void
    let onSharePressed: (String) -> Void

    @State private var inBookmarks: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(event.date)
                    .font(.headline)
                    .multilineTextAlignment(.trailing)

                Badge(title: event.language.uppercased(), color: .secondary.opacity(0.7))

                Spacer()

                Badge(category: event.category)
            }

            Text(event.title)
                .font(.body)
                .multilineTextAlignment(.leading)

            if let subtitle = event.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            RowActions(
                inBookmarks: $inBookmarks,
                onBookmarkTap: { onBookmarkPressed(event.id) },
                onCopyTap: { onCopyPressed(event.id) },
                onShareTap: { onSharePressed(event.id) }
            )
            .padding(.top, 4)
        }
        .padding(.horizontal)
        .onAppear {
            inBookmarks = event.inBookmarks
        }
    }
}

#Preview {
    BookmarkRow(
        event: BookmarkEvent(
            id: "123",
            date: "25 September",
            language: "en",
            title: "Heritage Day (South Africa)",
            subtitle: "",
            inBookmarks: true,
            category: .events
        ),
        onBookmarkPressed: { _ in },
        onCopyPressed: { _ in },
        onSharePressed: { _ in }
    )
}
