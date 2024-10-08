//
//  NetworkServiceMock.swift
//  this-day-tests
//
//  Created by Sergey Bendak on 17.09.2024.
//

import Foundation
import Combine

@testable import this_day

final class NetworkServiceMock: NetworkServiceProtocol {
    
    var day: DayNetworkModel?
    var error: NetworkError?
    
    var fetchEventsCalled: Bool = false

    func fetchEvents(for date: Date, language: String) -> AnyPublisher<DayNetworkModel, NetworkError> {
        fetchEventsCalled = true
        
        if let error = error {
            return Fail(error: error).eraseToAnyPublisher()
        } else if let day = day {
            return Just(day)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        } else {
            return Empty().eraseToAnyPublisher()
        }
    }
}
