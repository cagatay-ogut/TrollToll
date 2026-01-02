//
//  Match.swift
//  TrollToll
//
//  Created by Cagatay on 31.12.2025.
//

import Foundation

struct Match: Codable, Hashable, Identifiable {
    let id: String
    let status: MatchStatus
    let host: User
    let players: [User]
    let createdAt: Date
    var state: MatchState

    init(id: String, status: MatchStatus, host: User, players: [User] = [], createdAt: Date = Date()) {
        self.id = id
        self.status = status
        self.host = host
        self.players = players
        self.createdAt = createdAt
        self.state = MatchState(turn: 1, currentPlayerId: host.id)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.status = try container.decode(MatchStatus.self, forKey: .status)
        self.host = try container.decode(User.self, forKey: .host)
        self.players = try container.decodeIfPresent([User].self, forKey: .players) ?? []
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.state = try container.decode(MatchState.self, forKey: .state)
    }
}

enum MatchStatus: Int, Codable {
    case waitingForPlayers, playing, ended
}

struct MatchState: Codable, Hashable {
    var turn: Int
    var currentPlayerId: String
}
