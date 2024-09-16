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
    
    func toFormat(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
