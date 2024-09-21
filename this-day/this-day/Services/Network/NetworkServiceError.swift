//
//  NetworkServiceError.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation

enum NetworkServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case parsingError(String)
    case unknownError(String)
}
