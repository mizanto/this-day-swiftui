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
                .navigationTitle(LocalizedString("tab_title.bookmarks"))
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(item: $viewModel.itemsForSahre) { shareableItems in
            ActivityViewController(activityItems: shareableItems.items)
        }
        .snackbar(isPresented: $viewModel.showSnackbar, message: viewModel.snackbarMessage)
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .initial, .loading:
            showLoading()

        case .data(let events):
            if events.isEmpty {
                showPlaceholder(message: LocalizedString("message.placeholder.empty_bookmarks"))
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
                .scrollIndicators(.hidden)
                .listStyle(PlainListStyle())
            }

        case .error(_):
            showPlaceholder(message: LocalizedString("message.placeholder.empty_bookmarks"))
        }
    }

    private func onBookmarkPressed(id: String) {
        viewModel.removeBookmark(for: id)
    }

    private func onCopyPressed(id: String) {
        viewModel.copyToClipboardBookmark(id: id)
    }

    private func onSharePressed(id: String) {
        viewModel.shareBookmark(id: id)
    }
}
