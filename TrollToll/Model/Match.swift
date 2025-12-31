//
//  Match.swift
//  TrollToll
//
//  Created by Cagatay on 31.12.2025.
//

import Foundation

struct Match: Codable, Equatable {
    let status: MatchStatus
    let hostId: String
    let playerIds: [String]
    let createdAt: Date
}

enum MatchStatus: Codable {
    case waitingForPlayers, playing, ended
}
