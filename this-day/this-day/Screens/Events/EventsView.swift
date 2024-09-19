//
//  ContentView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct EventsView<ViewModel: EventsViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(viewModel.title)
        }
        .onAppear {
            AppLogger.shared.info("EventsView appeared, starting to fetch events.", category: .ui)
            viewModel.fetchEvents(for: Date())
        }
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .loading:
            let _ = AppLogger.shared.info("Loading view is displayed.",
                                          category: .ui)
            loadingView()

        case .loaded(let events):
            let _ = AppLogger.shared.info("Events loaded and list view is displayed with \(events.count) events.",
                                          category: .ui)
            eventsListView(events: events)

        case .error(let message):
            let _ = AppLogger.shared.error("Error view is displayed with message: \(message)",
                                           category: .ui)
            errorView(message: message)
        }
    }

    private func loadingView() -> some View {
        ProgressView("Loading events...")
            .progressViewStyle(CircularProgressViewStyle())
    }

    private func eventsListView(events: [Event]) -> some View {
        List(events) { event in
            VStack(alignment: .leading, spacing: 8) {
                Text(event.year)
                    .font(.headline)
                Text(event.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.body)
                .padding()
            Button(
                action: {
                    AppLogger.shared.info("Retrying to fetch events after error: \(message)", category: .ui)
                    viewModel.fetchEvents(for: Date())
                },
                label: {
                    Text("Try Again")
                        .foregroundColor(.blue)
                }
            )
        }
    }
}

#Preview {
    EventsView(viewModel: EventsViewModel(router: EventsRouter()))
}
