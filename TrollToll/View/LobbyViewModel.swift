//
//  LobbyViewModel.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import OSLog
import SwiftUI

@Observable
class LobbyViewModel {
    let user: User
    let lobbyService: LobbyService = FBLobbyService()
    let gameService: GameService = FBGameService()
    var match: Match?
    var gameState: GameState?
    var matches: [Match] = []
    var errorMessage: String?

    var readyToStart: Bool {
        if let match {
            return !match.players.isEmpty
        }
        return false
    }

    init(user: User) {
        self.user = user
    }

    func leaveLobby() async {
        if user.isHost {
            await cancelMatch()
        } else {
            await leaveMatch()
        }
    }

    private func cancelMatch() async {
        guard let matchId = match?.id else {
            errorMessage = ServerError.matchNotSet.localizedDescription
            return
        }

        do {
            try await lobbyService.cancelMatch(of: matchId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func leaveMatch() async {
        guard let matchId = match?.id else {
            errorMessage = ServerError.matchNotSet.localizedDescription
            return
        }

        do {
            try await lobbyService.leaveMatch(of: matchId, with: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startGame() async {
        guard let match else {
            errorMessage = ServerError.matchNotSet.localizedDescription
            return
        }

        do {
            let game = GameState(from: match)
            try await gameService.createGame(with: GameState(from: match))
            self.gameState = game
            try await lobbyService.startMatch(of: match.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func hostMatch() async {
        do {
            match = try await lobbyService.hostMatch(with: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeMatch() async {
        guard let matchId = match?.id else { return }

        do {
            for try await matchData in try await lobbyService.streamMatch(of: matchId) {
                match = matchData
                if match?.status == .playing, gameState == nil {
                    await fetchGame(with: matchId)
                }
                Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
            }
        } catch {
            match = nil
            Logger.multiplayer.error("Error observing match: \(error)")
        }

        match = nil
        Logger.multiplayer.debug("Observation ended")
    }

    func joinMatch(_ match: Match) async {
        do {
            try await lobbyService.joinMatch(match, with: user)
            self.match = match
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeLobbyMatches() async {
        matches = []
        for await matchesData in await lobbyService.streamLobbyMatches() {
            matches = matchesData
            Logger.multiplayer.debug("Lobby matches updated: \(matchesData.count)")
        }
        Logger.multiplayer.debug("Lobby matches observation ended")
    }

    func fetchGame(with id: String) async {
        do {
            gameState = try await gameService.fetchGame(with: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
