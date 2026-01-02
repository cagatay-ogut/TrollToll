//
//  FBMultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import FirebaseAuth
import FirebaseDatabase
import OSLog
import SwiftUI

@Observable
class FBMultiplayerServer: NSObject, MultiplayerServer {
    let user: User
    let dbRef: DatabaseReference
    let matchesRef: DatabaseReference
    var match: Match?
    var matches: [Match] = []
    var observeTask: Task<Void, Error>?

    var readyToStart: Bool {
        if let match {
            return !match.players.isEmpty
        }
        return false
    }

    init(user: User) {
        self.user = user
        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        matchesRef = dbRef.child("matches")
    }

    func observeMatch() async throws {
        guard let matchId = match?.id else {
            throw MultiplayerServerError.matchNotSet
        }

        observeTask = Task {
            do {
                for try await matchData in matchStream(matchId: matchId) {
                    match = matchData
                    Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
                }
            } catch {
                match = nil
                throw error
            }
        }

        _ = try await observeTask?.value
    }

    private func matchStream(matchId: String) -> AsyncThrowingStream<Match, Error> {
        AsyncThrowingStream { continuation in
            let matchRef = matchesRef.child(matchId)

            let handle = matchRef.observe(.value) { snapshot in
                do {
                    guard snapshot.exists(), let value = snapshot.value else {
                        continuation.finish(throwing: MultiplayerServerError.noMatchFound)
                        return
                    }
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let match = try JSONDecoder().decode(Match.self, from: data)
                    continuation.yield(match)
                } catch {
                    continuation.finish(throwing: MultiplayerServerError.failedToDecode(underlyingError: error))
                }
            } withCancel: { error in
                continuation.finish(throwing: MultiplayerServerError.serverCancel(underlyingError: error))
            }

            continuation.onTermination = { _ in
                matchRef.removeObserver(withHandle: handle)
            }
        }
    }

    func stopObservingMatch() {
        observeTask?.cancel()
        observeTask = nil
    }

    func hostMatch() async throws {
        let matchRef = matchesRef.childByAutoId()
        guard let matchId = matchRef.key else {
            throw MultiplayerServerError.serverFail
        }
        let match = Match(id: matchId, status: .waitingForPlayers, host: user)

        let dictionary: [String: Any]
        do {
            let data = try JSONEncoder().encode(match)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw MultiplayerServerError.unexpectedDataFormat
            }
            dictionary = dict
        } catch {
            throw MultiplayerServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await matchRef.setValue(dictionary)
            self.match = match
            Logger.multiplayer.debug("Created match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not host match: \(matchId), error: \(error)")
            throw MultiplayerServerError.serverError(underlyingError: error)
        }
    }

    func cancelMatch() async throws {
        guard let matchId = match?.id else {
            throw MultiplayerServerError.matchNotSet
        }

        let matchRef = matchesRef.child(matchId)
        do {
            try await matchRef.removeValue()
            Logger.multiplayer.debug("Deleted match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not delete match: \(matchId), error: \(error)")
            throw MultiplayerServerError.serverError(underlyingError: error)
        }
    }

    func startMatch() async throws {
        guard let matchId = match?.id else {
            throw MultiplayerServerError.matchNotSet
        }

        let matchRef = matchesRef.child(matchId)
        let updateData: [String: Any] = [
            "status": MatchStatus.playing.rawValue
        ]
        do {
            try await matchRef.updateChildValues(updateData)
            Logger.multiplayer.debug("Host started match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update status when starting match: \(matchId)")
            throw MultiplayerServerError.serverError(underlyingError: error)
        }
    }

    func findMatches() async throws {
        self.matches = try await withCheckedThrowingContinuation { continuation in
            matchesRef.observeSingleEvent(of: .value) { snapshot in
                guard snapshot.exists(), let value = snapshot.value else {
                    continuation.resume(returning: [])
                    return
                }

                do {
                    guard let matchesDict = value as? [String: Any] else {
                        throw MultiplayerServerError.unexpectedDataFormat
                    }

                    var matches: [Match] = []
                    for (_, matchDict) in matchesDict {
                        let data = try JSONSerialization.data(withJSONObject: matchDict)
                        let match = try JSONDecoder().decode(Match.self, from: data)
                        matches.append(match)
                    }
                    continuation.resume(returning: matches)
                } catch {
                    continuation.resume(throwing: MultiplayerServerError.failedToDecode(underlyingError: error))
                }
            }
        }
    }

    func joinMatch(_ match: Match) async throws {
        let playersRef = matchesRef.child(match.id).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: MultiplayerServerError.serverCancel(underlyingError: error))
            }
        }

        var currentPlayers: [User] = []
        if let value = playerSnapshot.value as? [Any] {
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                currentPlayers = try JSONDecoder().decode([User].self, from: data)
            } catch {
                throw MultiplayerServerError.failedToDecode(underlyingError: error)
            }
        }

        guard !currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(self.user.id) is already in the match: \(match.id)")
            throw MultiplayerServerError.playerAlreadyInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.append(user)

        let playersArray: Any
        do {
            let data = try JSONEncoder().encode(updatedPlayers)
            playersArray = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw MultiplayerServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await playersRef.setValue(playersArray)
            self.match = match
            Logger.multiplayer.debug("User \(self.user.id) joined match: \(match.id)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for joining match: \(match.id), error: \(error)")
            throw MultiplayerServerError.serverError(underlyingError: error)
        }
    }

    func leaveMatch() async throws {
        guard let matchId = match?.id else {
            throw MultiplayerServerError.matchNotSet
        }
        let playersRef = matchesRef.child(matchId).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: MultiplayerServerError.serverCancel(underlyingError: error))
            }
        }

        guard let snapshotValue = playerSnapshot.value else {
            throw MultiplayerServerError.unexpectedDataFormat
        }

        var currentPlayers: [User] = []
        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue)
            currentPlayers = try JSONDecoder().decode([User].self, from: data)
        } catch {
            throw MultiplayerServerError.failedToDecode(underlyingError: error)
        }

        guard currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(self.user.id) is not in the match: \(matchId)")
            throw MultiplayerServerError.playerNotInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.removeAll { $0 == user }

        let playersArray: Any
        do {
            let data = try JSONEncoder().encode(updatedPlayers)
            playersArray = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw MultiplayerServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await playersRef.setValue(playersArray)
            self.match = match
            Logger.multiplayer.debug("User \(self.user.id) left match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for leaving match: \(matchId), error: \(error)")
            throw MultiplayerServerError.serverError(underlyingError: error)
        }
    }
}
