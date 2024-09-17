//
//  ViewState.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation

enum ViewState<T> {
    case loading
    case loaded(T)
    case error(String)
}
