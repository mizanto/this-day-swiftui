//
//  Array+Extension.swift
//  this-day
//
//  Created by Sergey Bendak on 8.10.2024.
//

import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
    }
}
