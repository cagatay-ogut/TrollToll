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
    let gameService: GameService = FBGameService()
    let lobbyService: LobbyService = FBLobbyService()
    var errorMessage: String?

    var isPlayerTurn: Bool {
        match.state.currentPlayerId == user.id
    }

    init(user: User, match: Match) {
        self.user = user
        self.match = match
    }

    func endPlayerTurn() async {
        do {
            match = try await gameService.endPlayerTurn(of: user, in: match.id)
        } catch {
            errorMessage = error.localizedDescription
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

        Logger.multiplayer.debug("Observation ended")
    }
}
