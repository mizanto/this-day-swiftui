//
//  StorageServiceError.swift
//  this-day
//
//  Created by Sergey Bendak on 24.09.2024.
//

import Foundation

enum StorageServiceError: Error {
    case dataNotFound(String)
    case fetchError(Error)
    case saveError(Error)
    case deleteError(Error)
    case unknownError(String)
}
