//
//  String.swift
//  this-day
//
//  Created by Sergey Bendak on 30.09.2024.
//

import Foundation
import CryptoKit

extension String {
    func capitalizedFirstLetter() -> String {
        guard let firstCharacter = self.first else { return self }
        return firstCharacter.uppercased() + self.dropFirst()
    }

    func sha256Hash(short: Bool = false, length: Int = 4) -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        if short {
            return String(hashString.prefix(length))
        } else {
            return hashString
        }
    }
}
