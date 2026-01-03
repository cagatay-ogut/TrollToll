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
    var match: Match?
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

    func startMatch() async {
        guard let matchId = match?.id else {
            errorMessage = ServerError.matchNotSet.localizedDescription
            return
        }

        do {
            try await lobbyService.startMatch(of: matchId)
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
}
