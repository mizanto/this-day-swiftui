//
//  ViewState.swift
//  this-day
//
//  Created by Sergey Bendak on 20.09.2024.
//

import Foundation

enum ViewState<T> {
    case loading
    case data(T)
    case error(String)
}

extension ViewState: Equatable {
    static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.data, .data): return true
        case (.error, .error): return true
        default: return false
        }
    }
}
