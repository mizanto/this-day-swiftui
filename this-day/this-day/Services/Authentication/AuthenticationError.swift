//
//  AuthenticationError.swift
//  this-day
//
//  Created by Sergey Bendak on 1.10.2024.
//

import Foundation

enum AuthenticationError: Error {
    case invalidName
    case invalidEmail
    case weakPassword
    case loginFailed
    case creationFailed
    case updateFailed
    case logoutFailed
    case unknownError(description: String)
}
