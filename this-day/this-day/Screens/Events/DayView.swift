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
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            .listStyle(PlainListStyle())
        }
    }

    @ViewBuilder
    private func row(for category: EventCategory, event: any EventProtocol) -> some View {
        if let event = event as? ShortEvent {
            ShortEventRow(event: event)
        } else if let event = event as? DefaultEvent {
            DefaultEventRow(event: event)
        } else if let event = event as? ExtendedEvent {
            ExtendedEventRow(event: event)
        } else {
            Text("Unknown event type")
                .foregroundColor(.red)
                .italic()
        }
    }
}

#Preview {
    DayView(viewModel: DayViewModel())
}
