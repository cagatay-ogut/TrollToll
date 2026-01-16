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
    private let turnTime: Int = 60
    let user: User
    var match: Match
    var gameState: GameState
    let gameService: GameRepo = FBGameRepo()
    let lobbyService: LobbyRepo = FBLobbyRepo()
    var errorMessage: String?
    var infoMessage: String?
    var turnTimeLeft: Int = 0
    var hostLeft = false
    var lastPlayerId: String?
    private var exitedPlayers: [User] = []
    private var turnTimerTask: Task<Void, Never>?
    private var tempGameState: GameState

    var currentPlayerName: String {
        gameState.players.first { $0.id == gameState.currentPlayerId }!.name
    }

    var canTakeCard: Bool {
        isPlayerTurn && !gameState.progress.isFinished
    }

    var canPutToken: Bool {
        isPlayerTurn && (gameState.playerTokens[user.id] ?? 0 > 0) && !gameState.progress.isFinished
    }

    var isPlayerTurn: Bool {
        gameState.currentPlayerId == user.id
    }

    private var isUserHost: Bool {
        match.host == user
    }

    private var isExitedPlayersTurn: Bool {
        exitedPlayers.contains { $0.id == gameState.currentPlayerId }
    }
    private var isCardLeft: Bool {
        !tempGameState.deckCards.isEmpty
    }

    init(user: User, match: Match, gameState: GameState) {
        self.user = user
        self.match = match
        self.gameState = gameState
        self.tempGameState = gameState
    }

    func name(for playerId: String) -> String {
        gameState.players.first { $0.id == playerId }!.name
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
        let card = tempGameState.deckCards.removeFirst()
        if tempGameState.playerCards[gameState.currentPlayerId] != nil {
            tempGameState.playerCards[gameState.currentPlayerId]?.append(card)
        } else {
            tempGameState.playerCards[gameState.currentPlayerId] = [card]
        }
        tempGameState.playerCards[gameState.currentPlayerId]?.sort()

        let prevTokenCount = tempGameState.playerTokens[user.id] ?? 0
        tempGameState.playerTokens[user.id] = prevTokenCount + gameState.tokenInMiddle
        tempGameState.tokenInMiddle = 0

        endPlayerTurn()
        if !isCardLeft {
            finishGame()
        }

        do {
            try await gameService.updateGame(for: gameState.matchId, with: tempGameState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func putToken() async {
        let currentTokenCount = tempGameState.playerTokens[user.id]!
        tempGameState.playerTokens[user.id] = currentTokenCount - 1
        tempGameState.tokenInMiddle += 1

        endPlayerTurn()

        do {
            try await gameService.updateGame(for: gameState.matchId, with: tempGameState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func endPlayerTurn() {
        cancelTurnTimer()

        let currentPlayerIndex = tempGameState.players.firstIndex { $0.id == tempGameState.currentPlayerId }!
        if currentPlayerIndex + 1 == tempGameState.players.count {
            tempGameState.currentPlayerId = tempGameState.players[0].id
            tempGameState.turn += 1
        } else {
            tempGameState.currentPlayerId = tempGameState.players[currentPlayerIndex + 1].id
        }
    }

    private func finishGame() {
        cancelTurnTimer()

        let victor = tempGameState.players.max { point(for: $0.id) < point(for: $1.id) }!
        tempGameState.progress = .finished(victorId: victor.id)
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeMatch() async {
        do {
            for try await matchData in try await lobbyService.streamMatch(of: match.id) {
                self.match = matchData
                if isUserHost, match.players.count + 1 != gameState.players.count {
                    await onPlayersExited()
                }
                Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
            }
        } catch {
            Logger.multiplayer.error("Error observing match: \(error)")
        }

        await leaveMatch()
        if match.host != user {
            hostLeft = true
        }
        Logger.multiplayer.debug("Match observation ended")
    }

    func observeGame() async {
        do {
            for try await gameData in try await gameService.streamGame(of: match.id) {
                // only change last player id if current player id change, i.e first round doesn't change
                lastPlayerId = gameData.currentPlayerId != gameState.currentPlayerId ? gameState.currentPlayerId : nil
                self.gameState = gameData
                self.tempGameState = gameState
                if isPlayerTurn {
                    startTurnTimer()
                }
                if isExitedPlayersTurn {
                    try? await Task.sleep(for: .seconds(1))
                    await takeCard() // takes card for exited player
                }
                Logger.multiplayer.debug("Game updated: \(String(describing: gameData))")
            }
        } catch {
            Logger.multiplayer.error("Error observing game: \(error)")
        }

        Logger.multiplayer.debug("Game observation ended")
    }

    private func startTurnTimer() {
        turnTimerTask?.cancel()

        turnTimeLeft = turnTime
        turnTimerTask = Task {
            do {
                for second in stride(from: turnTime, to: 0, by: -1) {
                    await MainActor.run {
                        turnTimeLeft = second
                    }

                    try await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                }
                await takeCard()
            } catch {
                // cancelled task, player played
            }
        }
    }

    private func cancelTurnTimer() {
        turnTimerTask?.cancel()
        turnTimerTask = nil
    }

    private func onPlayersExited() async {
        exitedPlayers = gameState.players.filter {
            $0 != user && !match.players.contains($0)
        }
        let names = exitedPlayers.map { $0.name }
        infoMessage = "Players left: \(names)"
        if isExitedPlayersTurn {
            try? await Task.sleep(for: .seconds(1))
            await takeCard()
        }
        Logger.multiplayer.debug("Exited player list: \(self.exitedPlayers)")
    }
}
