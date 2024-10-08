//
//  DayView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct DayView<ViewModel: DayViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(viewModel.title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(item: $viewModel.itemsForSahre) { shareableItems in
            ActivityViewController(activityItems: shareableItems.items) {
                viewModel.onCompleteShare()
            }
        }
        .snackbar(isPresented: $viewModel.showSnackbar, message: viewModel.snackbarMessage)
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .initial, .loading:
            showLoading()
        case .data(let events):
            dayView(for: events)
        case .error(let message):
            showError(
                message: message,
                action: viewModel.onTryAgain
            )
        }
    }

    private func dayView(for events: [Event]) -> some View {
        VStack {
            Group {
                CategoryPicker(selectedCategory: $viewModel.selectedCategory)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
            }
            .background(.main)

            ScrollViewReader { proxy in
                List(events, id: \.id) { event in
                    row(for: viewModel.selectedCategory, event: event)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                .scrollIndicators(.hidden)
                .listStyle(PlainListStyle())
                .id(viewModel.selectedCategory)
                .onChange(of: viewModel.selectedCategory) {
                    withAnimation {
                        proxy.scrollTo(events.first?.id, anchor: .top)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for category: EventCategory, event: Event) -> some View {
        ExtendedEventRow(
            event: event,
            onBookmarkPressed: toggleBookmark,
            onCopyPressed: copyToClipboard,
            onSharePressed: share
        )
    }

    private func toggleBookmark(for id: String) {
        viewModel.toggleBookmark(for: id)
    }

    private func copyToClipboard(for id: String) {
        viewModel.copyToClipboardEvent(id: id)
    }

    private func share(for id: String) {
        viewModel.shareEvent(id: id)
    }
}

#Preview {
//    DayView(viewModel: DayViewModel())
}
