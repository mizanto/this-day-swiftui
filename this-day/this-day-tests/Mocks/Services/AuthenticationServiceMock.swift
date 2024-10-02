//
//  AuthenticationServiceMock.swift
//  this-day
//
//  Created by Sergey Bendak on 2.10.2024.
//

import Foundation
import Combine

@testable import this_day

final class AuthenticationServiceMock: AuthenticationServiceProtocol {
    var name: String = ""
    var email: String = ""

    @Published private var _currentUser: UserInfoModel?

    var currentUser: UserInfoModel? {
        return _currentUser
    }

    var isAuthenticated: Bool {
        return _currentUser != nil
    }

    var currentUserPublisher: AnyPublisher<UserInfoModel?, Never> {
        $_currentUser.eraseToAnyPublisher()
    }

    var signInResult: Result<Void, AuthenticationError> = .failure(.loginFailed)
    var signUpResult: Result<Void, AuthenticationError> = .failure(.creationFailed)
    var signOutResult: Result<Void, AuthenticationError> = .failure(.logoutFailed)

    private var cancellables = Set<AnyCancellable>()

    func signIn(email: String, password: String) -> AnyPublisher<Void, AuthenticationError> {
        return Future { [weak self] promise in
            guard let self else { return }
            switch self.signInResult {
            case .success:
                self._currentUser = UserInfoModel(name: name, email: email)
                promise(.success(()))
            case .failure(let error):
                self._currentUser = nil
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func signUp(name: String, email: String, password: String) -> AnyPublisher<Void, AuthenticationError> {
        return Future { [weak self] promise in
            guard let self else { return }
            switch self.signUpResult {
            case .success:
                self._currentUser = UserInfoModel(name: name, email: email)
                promise(.success(()))
            case .failure(let error):
                self._currentUser = nil
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func signOut() -> AnyPublisher<Void, AuthenticationError> {
        return Future { [weak self] promise in
            guard let self else { return }
            switch self.signOutResult {
            case .success:
                self._currentUser = nil
                promise(.success(()))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
