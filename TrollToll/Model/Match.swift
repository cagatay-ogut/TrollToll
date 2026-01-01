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
    let hostId: String
    let playerIds: [String]
    let createdAt: Date

    init(id: String, status: MatchStatus, hostId: String, playerIds: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.status = status
        self.hostId = hostId
        self.playerIds = playerIds
        self.createdAt = createdAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.status = try container.decode(MatchStatus.self, forKey: .status)
        self.hostId = try container.decode(String.self, forKey: .hostId)
        self.playerIds = try container.decodeIfPresent([String].self, forKey: .playerIds) ?? []
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

enum MatchStatus: Int, Codable {
    case waitingForPlayers, readyToStart, playing, ended
}
