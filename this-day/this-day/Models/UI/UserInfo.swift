//
//  UserInfo.swift
//  this-day
//
//  Created by Sergey Bendak on 2.10.2024.
//

import Foundation

struct UserInfo {
    let name: String
    let email: String
    
    init (name: String, email: String) {
        self.name = name
        self.email = email
    }
    
    init?(model: UserInfoModel?) {
        guard let model else { return nil }
        name = model.name
        email = model.email
    }
}
