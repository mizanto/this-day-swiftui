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
            ActivityViewController(activityItems: shareableItems.items)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .loading:
            showLoading(message: "Loading...")
        case .data(let events):
            dayView(for: events)
        case .error(let message):
            showError(
                message: message,
                action: viewModel.onTryAgain
            )
        }
    }

    private func dayView(for events: [any EventProtocol]) -> some View {
        VStack {
            CategoryPicker(selectedCategory: $viewModel.selectedCategory)
                .padding(.horizontal)

            Text(viewModel.subtitle)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            List(events, id: \.id) { event in
                row(for: viewModel.selectedCategory, event: event)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
        }
    }

    @ViewBuilder
    private func row(for category: EventCategory, event: any EventProtocol) -> some View {
        if let event = event as? ShortEvent {
            ShortEventRow(
                event: event,
                onBookmarkPressed: toggleBookmark,
                onCopyPressed: copyToClipboard,
                onSharePressed: share
            )
        } else if let event = event as? ExtendedEvent {
            ExtendedEventRow(
                event: event,
                onBookmarkPressed: toggleBookmark,
                onCopyPressed: copyToClipboard,
                onSharePressed: share
            )
        } else {
            Text("Unknown event type")
                .foregroundColor(.red)
                .italic()
        }
    }

    private func toggleBookmark(for id: UUID) {
        viewModel.toggleBookmark(for: id)
    }

    private func copyToClipboard(for id: UUID) {
        viewModel.copyToClipboardEvent(id: id)
    }

    private func share(for id: UUID) {
        viewModel.shareEvent(id: id)
    }
}

#Preview {
//    DayView(viewModel: DayViewModel())
}
