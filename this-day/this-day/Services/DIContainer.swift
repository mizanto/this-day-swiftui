//
//  DIContainer.swift
//  this-day
//
//  Created by Sergey Bendak on 17.09.2024.
//

final class DIContainer {
    static let shared = DIContainer()

    private var services: [String: Any] = [:]

    private init() {}

    func register<T>(_ service: T) {
        let key = String(describing: T.self)
        services[key] = service
    }

    func resolve<T>() -> T? {
        let key = String(describing: T.self)
        return services[key] as? T
    }
}
