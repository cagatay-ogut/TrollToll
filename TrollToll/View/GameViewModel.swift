//
//  GameViewModel.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import OSLog
import SwiftUI

@Observable
class GameViewModel {
    let user: User
    var match: Match
    var gameState: GameState
    let gameService: GameRepo = FBGameRepo()
    let lobbyService: LobbyRepo = FBLobbyRepo()
    var errorMessage: String?

    var isPlayerTurn: Bool {
        gameState.currentPlayerId == user.id
    }

    var canPutToken: Bool {
        gameState.playerTokens[user.id] ?? 0 > 0
    }

    var currentPlayerName: String {
        gameState.players.first { $0.id == gameState.currentPlayerId }!.name
    }

    init(user: User, match: Match, gameState: GameState) {
        self.user = user
        self.match = match
        self.gameState = gameState
    }

    func point(for playerId: String) -> Int {
        let cards = gameState.playerCards[playerId] ?? []
        var lowestCards: [Int] = []
        for (index, value) in cards.enumerated() {
            if index == 0 || value != cards[index - 1] + 1 {
                lowestCards.append(cards[index])
            }
        }

        return gameState.playerTokens[playerId]! - lowestCards.reduce(0, +)
    }

    func takeCard() async {
        let card = gameState.middleCards.removeFirst()
        if gameState.playerCards[gameState.currentPlayerId] != nil {
            gameState.playerCards[gameState.currentPlayerId]?.append(card)
        } else {
            gameState.playerCards[gameState.currentPlayerId] = [card]
        }
        gameState.playerCards[gameState.currentPlayerId]?.sort()

        let prevTokenCount = gameState.playerTokens[user.id] ?? 0
        gameState.playerTokens[user.id] = prevTokenCount + gameState.tokenInMiddle
        gameState.tokenInMiddle = 0

        endPlayerTurn()

        do {
            gameState = try await gameService.updateGame(for: gameState.matchId, with: gameState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func putToken() async {
        let currentTokenCount = gameState.playerTokens[user.id]!
        gameState.playerTokens[user.id] = currentTokenCount - 1
        gameState.tokenInMiddle += 1

        endPlayerTurn()

        do {
            gameState = try await gameService.updateGame(for: gameState.matchId, with: gameState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func endPlayerTurn() {
        let currentPlayerIndex = gameState.players.firstIndex(of: user)!
        if currentPlayerIndex + 1 == gameState.players.count {
            gameState.currentPlayerId = gameState.players[0].id
            gameState.turn += 1
        } else {
            gameState.currentPlayerId = gameState.players[currentPlayerIndex + 1].id
        }
    }

    func cancelMatch() async {
        do {
            try await lobbyService.cancelMatch(of: match.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveMatch() async {
        do {
            try await lobbyService.leaveMatch(of: match.id, with: user)
            self.match = try await lobbyService.fetchMatch(of: match.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeMatch() async {
        do {
            for try await matchData in try await lobbyService.streamMatch(of: match.id) {
                self.match = matchData
                Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
            }
        } catch {
            Logger.multiplayer.error("Error observing match: \(error)")
        }

        Logger.multiplayer.debug("Match observation ended")
    }

    func observeGame() async {
        do {
            for try await gameData in try await gameService.streamGame(of: match.id) {
                self.gameState = gameData
                Logger.multiplayer.debug("Game updated: \(String(describing: gameData))")
            }
        } catch {
            Logger.multiplayer.error("Error observing game: \(error)")
        }

        Logger.multiplayer.debug("Game observation ended")
    }
}
