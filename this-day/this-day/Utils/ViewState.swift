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
