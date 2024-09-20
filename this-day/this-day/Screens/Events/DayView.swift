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
        case .data(let day):
            dayView(for: day)
        case .error(let message):
            showError(
                message: message,
                action: {
                    AppLogger.shared.info("Retrying to fetch events after error: \(message)", category: .ui)
                    viewModel.onTryAgain()
                }
            )
        }
    }

    private func dayView(for day: Day) -> some View {
        VStack {
            CategoryPicker(selectedCategory: $viewModel.selectedCategory)
                .padding(.horizontal)

            Text(day.text)
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.top, 8)

            List(day.events) { event in
                EventRow(event: event)
            }
            .listStyle(PlainListStyle())
        }
    }
}

#Preview {
    DayView(viewModel: DayViewModel())
}
