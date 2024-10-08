//
//  RowActions.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct RowActions: View {
    @Binding var inBookmarks: Bool

    var onBookmarkTap: VoidClosure
    var onCopyTap: VoidClosure
    var onShareTap: VoidClosure

    var body: some View {
        HStack {
            Image(systemName: inBookmarks ? "bookmark.fill" : "bookmark")
                .foregroundStyle(inBookmarks ? .orange : .gray)
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
