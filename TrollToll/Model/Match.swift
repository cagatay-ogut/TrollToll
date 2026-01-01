//
//  Match.swift
//  TrollToll
//
//  Created by Cagatay on 31.12.2025.
//

import Foundation

struct Match: Codable, Equatable, Identifiable {
    let id: String
    let status: MatchStatus
    let host: User
    let players: [User]
    let createdAt: Date

    init(id: String, status: MatchStatus, host: User, players: [User] = [], createdAt: Date = Date()) {
        self.id = id
        self.status = status
        self.host = host
        self.players = players
        self.createdAt = createdAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.status = try container.decode(MatchStatus.self, forKey: .status)
        self.host = try container.decode(User.self, forKey: .host)
        self.players = try container.decodeIfPresent([User].self, forKey: .players) ?? []
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

enum MatchStatus: Int, Codable {
    case waitingForPlayers, playing, ended
}
