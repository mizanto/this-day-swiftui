//
//  StorageError.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation

enum StorageError: Error {
    case notFound
    case unauthorized
    case fetchError(Error)
    case saveError(Error)
    case deleteError(Error)
    case unknownError(String)
}
