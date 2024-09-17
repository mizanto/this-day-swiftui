//
//  ArticleView.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import SwiftUI

struct ArticleView<ViewModel: ArticleViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            contentView()
        }
        .onAppear {
            viewModel.fetchArticle()
        }
        .navigationTitle(viewModel.title)
    }

    @ViewBuilder
    private func contentView() -> some View {
        switch viewModel.state {
        case .loading:
            loadingView()
        case .loaded(let article):
            articleView(article: article)
        case .error(let message):
            errorView(message: message)
        }
    }

    private func loadingView() -> some View {
        ProgressView("Loading article...")
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }

    private func articleView(article: Article) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.text)
                    .font(.body)
                    .padding()

                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 100, height: 100)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.body)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()

            // Кнопка для повторной попытки загрузки статьи
            Button(
                action: {
                    viewModel.fetchArticle()
                },
                label: {
                    Text("Try Again")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            )
            .padding()
        }
    }
}

#Preview {
    ArticleView(viewModel: ArticleViewModel(topic: "Pope_Honorius_I"))
}
