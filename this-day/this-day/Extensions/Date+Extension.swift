//
//  Date+Extension.swift
//  this-day
//
//  Created by Sergey Bendak on 16.09.2024.
//

import Foundation

extension Date {
    var day: Int? {
        Calendar.current.dateComponents([.day], from: self).day
    }

    var month: Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }

    func isTheSamDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    func toFormat(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func toLocalizedDayMonth(language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.dateFormat = language == "ru" ? "d MMMM" : "MMMM d"
        return formatter.string(from: self)
    }
}
