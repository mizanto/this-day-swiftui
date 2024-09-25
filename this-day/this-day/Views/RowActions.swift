//
//  RowActions.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct RowActions: View {
    @Binding var inBookmarks: Bool

    var onBookmarkTap: () -> Void
    var onCopyTap: () -> Void
    var onShareTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: inBookmarks ? "bookmark.fill" : "bookmark")
                .foregroundStyle(inBookmarks ? .yellow : .gray)
                .scaledToFit()
                .onTapGesture {
                    onBookmarkTap()
                    inBookmarks.toggle()
                }
                .imageScale(.small)
            Image(systemName: "document.on.document")
                .foregroundStyle(.gray)
                .onTapGesture {
                    onCopyTap()
                }
                .imageScale(.small)
                .padding(.horizontal, 48)
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.gray)
                .imageScale(.small)
                .onTapGesture {
                    onShareTap()
                }
            Spacer()
        }
    }
}
