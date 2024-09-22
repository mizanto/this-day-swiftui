//
//  ResponseNetworkModel.swift
//  this-day
//
//  Created by Sergey Bendak on 22.09.2024.
//

struct ResponseNetworkModel: Codable {
    let query: QueryNetworkModel
}

struct QueryNetworkModel: Codable {
    let pages: [String: PageNetworkModel]
}

struct PageNetworkModel: Codable {
    let extract: String
}
