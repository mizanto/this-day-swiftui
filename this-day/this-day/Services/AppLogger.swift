//
//  AppLogger.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

import OSLog

final class AppLogger {

    static let shared = AppLogger()

    enum LogCategory: String {
        case network = "Network"
        // swiftlint:disable:next identifier_name
        case ui = "UI"
        case database = "Database"
        case `default` = "Default"

        var logger: Logger {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "UnknownSubsystem", category: self.rawValue)
        }
    }

    private init() {}

    func info(_ message: String, category: LogCategory = .default) {
        category.logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String, category: LogCategory = .default) {
        category.logger.error("\(message, privacy: .public)")
    }

    func debug(_ message: String, category: LogCategory = .default) {
        category.logger.debug("\(message, privacy: .public)")
    }

    func log(_ message: String, level: OSLogType, category: LogCategory = .default) {
        let logger = category.logger
        switch level {
        case .info:
            logger.info("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }
    }
}
