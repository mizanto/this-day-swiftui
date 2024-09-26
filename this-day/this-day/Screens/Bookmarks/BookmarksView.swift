//
//  BookmarksView.swift
//  this-day
//
//  Created by Sergey Bendak on 25.09.2024.
//

import SwiftUI

struct BookmarksView<ViewModel: BookmarksViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle("Bookmarks")
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(item: $viewModel.itemsForSahre) { shareableItems in
            ActivityViewController(activityItems: shareableItems.items)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .initial, .loading:
            showLoading(message: "Loading...")

        case .data(let events):
            if events.isEmpty {
                showPlaceholder(message: "No bookmarks yet.")
            } else {
                List(events) { event in
                    BookmarkRow(
                        event: event,
                        onBookmarkPressed: onBookmarkPressed,
                        onCopyPressed: onCopyPressed,
                        onSharePressed: onSharePressed
                    )
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }

        case .error(let message):
            showError(
                message: message,
                action: {}
            )
        }
    }

    private func onBookmarkPressed(id: UUID) {
        viewModel.removeBookmark(for: id)
    }

    private func onCopyPressed(id: UUID) {
        viewModel.copyToClipboardBookmark(id: id)
    }

    private func onSharePressed(id: UUID) {
        viewModel.shareBookmark(id: id)
    }
}
