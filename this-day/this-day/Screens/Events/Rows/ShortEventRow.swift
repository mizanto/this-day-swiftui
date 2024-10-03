//
//  ShortEventRow.swift
//  this-day
//
//  Created by Sergey Bendak on 23.09.2024.
//

import SwiftUI

struct ShortEventRow: View {
    let event: ShortEvent
    let onBookmarkPressed: (String) -> Void
    let onCopyPressed: (String) -> Void
    let onSharePressed: (String) -> Void

    @State private var inBookmarks: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.body)
                .padding(.horizontal)
                .padding(.bottom, 4)

            RowActions(
                inBookmarks: $inBookmarks,
                onBookmarkTap: { onBookmarkPressed(event.id) },
                onCopyTap: { onCopyPressed(event.id) },
                onShareTap: { onSharePressed(event.id) }
            )
            .padding(.leading)
        }
        .padding(.vertical, 8)
        .onAppear {
            inBookmarks = event.inBookmarks
        }
    }
}

#Preview {
    ShortEventRow(
        event: ShortEvent(
            id: "123",
            title: "Some long long long text.",
            inBookmarks: false
        ),
        onBookmarkPressed: { _ in },
        onCopyPressed: { _ in },
        onSharePressed: { _ in }
    )
}
