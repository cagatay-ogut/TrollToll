//
//  GameState.swift
//  TrollToll
//
//  Created by Cagatay on 3.01.2026.
//

struct GameState: Codable, Hashable {
    let matchId: String
    let players: [User]
    var turn: Int
    var currentPlayerId: String
    var playerTokens: [String: Int]
    var playerCards: [String: [Int]]
    var middleCards: [Int]
    var tokenInMiddle: Int

    init(from match: Match) {
        self.matchId = match.id
        self.turn = 1
        self.currentPlayerId = match.host.id
        self.players = [match.host] + match.players
        var tokens: [String: Int] = [:]
        var cards: [String: [Int]] = [:]
        players.forEach {
            tokens[$0.id] = 11
            cards[$0.id] = []
        }
        self.playerTokens = tokens
        self.playerCards = cards
        self.middleCards = Array(3...35).shuffled()
        self.tokenInMiddle = 0
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.matchId = try container.decode(String.self, forKey: .matchId)
        self.turn = try container.decode(Int.self, forKey: .turn)
        self.currentPlayerId = try container.decode(String.self, forKey: .currentPlayerId)
        self.players = try container.decode([User].self, forKey: .players)
        self.playerTokens = try container.decode([String: Int].self, forKey: .playerTokens)
        self.playerCards = try container.decodeIfPresent([String: [Int]].self, forKey: .playerCards)
            ?? Dictionary(uniqueKeysWithValues: players.map { ($0.id, []) })
        self.middleCards = try container.decode([Int].self, forKey: .middleCards)
        self.tokenInMiddle = try container.decode(Int.self, forKey: .tokenInMiddle)
    }
}
