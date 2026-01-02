//
//  User.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

struct User: Codable, Hashable {
    let id: String
    let name: String
    var isHost = false

    enum CodingKeys: CodingKey {
        case id, name
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
