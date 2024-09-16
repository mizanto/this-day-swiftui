//
//  ContentView.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import SwiftUI

struct EventsView<ViewModel: EventsViewModelProtocol,
                  Router: EventsRouterProtocol>: View {
    @StateObject private var viewModel: ViewModel
    private let router: Router

    init(viewModel: ViewModel, router: Router) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        NavigationView {
            content()
                .navigationTitle(viewModel.title)
        }
        .onAppear {
            viewModel.fetchEvents(for: Date())
        }
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.state {
        case .loading:
            loadingView()

        case .loaded(let events):
            eventsListView(events: events)

        case .error(let message):
            errorView(message: message)
        }
    }

    private func loadingView() -> some View {
        ProgressView("Loading events...")
            .progressViewStyle(CircularProgressViewStyle())
    }

    private func eventsListView(events: [Event]) -> some View {
        List(events) { event in
            NavigationLink(destination: router.view(for: event)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.year)
                        .font(.headline)
                    Text(event.text)
                        .font(.body)
                        .lineLimit(1)
                    HStack {
                        ForEach(event.links) { link in
                            Text(link.title)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
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
    EventsView(viewModel: EventsViewModel(), router: EventsRouter())
}
