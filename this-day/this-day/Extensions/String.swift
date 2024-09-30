//
//  String.swift
//  this-day
//
//  Created by Sergey Bendak on 30.09.2024.
//

import Foundation

extension String {
    func capitalizedFirstLetter() -> String {
        guard let firstCharacter = self.first else { return self }
        return firstCharacter.uppercased() + self.dropFirst()
    }
}
