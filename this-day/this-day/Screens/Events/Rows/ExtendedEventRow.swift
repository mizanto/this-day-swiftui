//
//  ExtendedEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import SwiftUI

struct ExtendedEventRow: View {
    let event: ExtendedEvent
    @State private var inBookmarks: Bool = false

    let onBookmarkPressed: (UUID) -> Void
    let onCopyPressed: (UUID) -> Void
    let onSharePressed: (UUID) -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text(event.year)
                .font(.headline)
                .multilineTextAlignment(.trailing)
                .frame(width: 60, alignment: .trailing)

            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 8)

                if let subtitle = event.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                }

                RowActions(
                    inBookmarks: $inBookmarks,
                    onBookmarkTap: { onBookmarkPressed(event.id) },
                    onCopyTap: { onCopyPressed(event.id) },
                    onShareTap: { onSharePressed(event.id) }
                )
            }
            .padding(.trailing)
            .onChange(of: event) { _, newValue in
                inBookmarks = newValue.inBookmarks
            }
        }
        .onAppear {
            inBookmarks = event.inBookmarks
        }
    }
}

#Preview {
    ExtendedEventRow(
        event: ExtendedEvent(
            year: "1998",
            title: "Text",
            subtitle: "Subtitle",
            inBookmarks: false
        ),
        onBookmarkPressed: { _ in },
        onCopyPressed: { _ in },
        onSharePressed: { _ in }
    )
}
