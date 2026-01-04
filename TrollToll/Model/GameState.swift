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
    var progress: GameProgress

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
        self.progress = .inProgress
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
        self.middleCards = try container.decodeIfPresent([Int].self, forKey: .middleCards) ?? []
        self.tokenInMiddle = try container.decode(Int.self, forKey: .tokenInMiddle)
        self.progress = try container.decode(GameProgress.self, forKey: .progress)
    }
}

enum GameProgress: Codable, Hashable {
    case inProgress, finished(victorId: String)

    var isFinished: Bool {
        switch self {
        case .inProgress:
            false
        case .finished:
            true
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case victorId
    }

    private enum ProgressType: String, Codable {
        case inProgress
        case finished
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .inProgress:
            try container.encode(ProgressType.inProgress, forKey: .type)
        case .finished(let victorId):
            try container.encode(ProgressType.finished, forKey: .type)
            try container.encode(victorId, forKey: .victorId)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ProgressType.self, forKey: .type)

        switch type {
        case .inProgress:
            self = .inProgress
        case .finished:
            let victorId = try container.decode(String.self, forKey: .victorId)
            self = .finished(victorId: victorId)
        }
    }
}
