//
//  UserInfoModel.swift
//  this-day
//
//  Created by Sergey Bendak on 2.10.2024.
//

import Foundation
import FirebaseAuth

struct UserInfoModel: Codable {
    let id: String
    let name: String
    let email: String

    init(from user: User) {
        self.id = user.uid
        self.email = user.email ?? ""
        self.name = user.displayName ?? ""
    }
}
