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
            loadingView()

        case .loaded(let day):
            VStack {
                Picker("Select Category", selection: $viewModel.selectedCategory) {
                    ForEach(EventCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 4)

                Text(day.text)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 4)

                eventsListView(events: day.events)
            }

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
            if event.text.isEmpty {
                Text(event.title)
                    .font(.headline)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                    Text(event.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func errorView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.body)
                .padding()
            Button(
                action: {
                    AppLogger.shared.info("Retrying to fetch events after error: \(message)", category: .ui)
                    viewModel.onTryAgain()
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
