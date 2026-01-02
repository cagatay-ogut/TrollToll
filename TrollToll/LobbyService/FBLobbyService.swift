//
//  FBLobbyService.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import FirebaseDatabase
import OSLog
import SwiftUI

// swiftlint:disable type_body_length
@Observable
class FBLobbyService: NSObject, LobbyService {
    let user: User
    let dbRef: DatabaseReference
    let matchesRef: DatabaseReference
    var match: Match?
    var matches: [Match] = []

    var readyToStart: Bool {
        if let match {
            return !match.players.isEmpty
        }
        return false
    }

    init(user: User, match: Match? = nil) {
        self.user = user
        self.match = match
        self.dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        self.matchesRef = dbRef.child("matches")
    }

    func observeMatch() async throws {
        guard let matchId = match?.id else {
            throw ServerError.matchNotSet
        }

        do {
            for try await matchData in matchStream(matchId: matchId) {
                match = matchData
                Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
            }
        } catch {
            match = nil
            throw error
        }

        match = nil
        Logger.multiplayer.debug("Observation ended")
    }

    private func matchStream(matchId: String) -> AsyncThrowingStream<Match, Error> {
        AsyncThrowingStream { continuation in
            let matchRef = matchesRef.child(matchId)

            let handle = matchRef.observe(.value) { snapshot in
                do {
                    guard snapshot.exists(), let value = snapshot.value else {
                        continuation.finish() // match ended
                        return
                    }
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let match = try JSONDecoder().decode(Match.self, from: data)
                    continuation.yield(match)
                } catch {
                    continuation.finish(throwing: ServerError.failedToDecode(underlyingError: error))
                }
            } withCancel: { error in
                continuation.finish(throwing: ServerError.serverCancel(underlyingError: error))
            }

            continuation.onTermination = { _ in
                matchRef.removeObserver(withHandle: handle)
            }
        }
    }

    func hostMatch() async throws {
        let matchRef = matchesRef.childByAutoId()
        guard let matchId = matchRef.key else {
            throw ServerError.serverFail
        }
        let match = Match(id: matchId, status: .waitingForPlayers, host: user)

        let dictionary: [String: Any]
        do {
            let data = try JSONEncoder().encode(match)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ServerError.unexpectedDataFormat
            }
            dictionary = dict
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await matchRef.setValue(dictionary)
            self.match = match
            Logger.multiplayer.debug("Created match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not host match: \(matchId), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func cancelMatch() async throws {
        guard let matchId = match?.id else {
            throw ServerError.matchNotSet
        }

        let matchRef = matchesRef.child(matchId)
        do {
            try await matchRef.removeValue()
            Logger.multiplayer.debug("Deleted match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not delete match: \(matchId), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func startMatch() async throws {
        guard let matchId = match?.id else {
            throw ServerError.matchNotSet
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
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func observeLobbyMatches() async {
        matches = []
        for await matchesData in lobbyMatchesStream() {
            matches = matchesData
            Logger.multiplayer.debug("Lobby matches updated: \(matchesData.count)")
        }
        Logger.multiplayer.debug("Lobby matches observation ended")
    }

    // swiftlint:disable:next function_body_length
    private func lobbyMatchesStream() -> AsyncStream<[Match]> {
        // swiftlint:disable:next closure_body_length
        AsyncStream { continuation in
            let query = matchesRef
                .queryOrdered(byChild: "status")
                .queryEqual(toValue: MatchStatus.waitingForPlayers.rawValue)

            var currentMatches: [Match] = []
            var observationHandles: [UInt] = []

            // --- CHILD ADDED ---
            let childAddedHandle = query.observe(.childAdded) { snapshot in
                do {
                    guard snapshot.exists(), let value = snapshot.value else {
                        Logger.multiplayer.error("LobbyMatchesObserve - ChildAdded: Snapshot does not have value")
                        return
                    }

                    let data = try JSONSerialization.data(withJSONObject: value)
                    let newMatch = try JSONDecoder().decode(Match.self, from: data)
                    currentMatches.append(newMatch)
                    continuation.yield(currentMatches)
                } catch {
                    Logger.multiplayer.error("LobbyMatchesObserve - ChildAdded: Decoding error: \(error)")
                }
            } withCancel: { error in
                Logger.multiplayer.error("LobbyMatchesObserve - ChildAdded: Firebase observer cancelled: \(error)")
                continuation.finish()
            }
            observationHandles.append(childAddedHandle)
            Logger.multiplayer.debug("LobbyMatchesObserve observing .childAdded events for lobby matches")

            // --- CHILD CHANGED ---
            let childChangedHandle = query.observe(.childChanged) { snapshot in
                do {
                    guard snapshot.exists(), let value = snapshot.value else {
                        Logger.multiplayer.error("LobbyMatchesObserve - ChildChanged: Snapshot does not have value")
                        return
                    }
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let updatedMatch = try JSONDecoder().decode(Match.self, from: data)

                    if let index = currentMatches.firstIndex(where: { $0.id == updatedMatch.id }) {
                        currentMatches[index] = updatedMatch
                        continuation.yield(currentMatches)
                    } else {
                        Logger.multiplayer
                            .warning("LobbyMatchesObserve - ChildChanged: Received match not in local list")
                        // It's possible for a match to change status TO 'waitingForPlayers'
                        // and trigger childChanged if it was previously observed by another query.
                        // Or if Firebase sends a childChanged for an item not yet in our initial .childAdded list.
                        // We should add it to ensure consistency.
                        currentMatches.append(updatedMatch)
                        continuation.yield(currentMatches)
                    }
                } catch {
                    Logger.multiplayer.error("LobbyMatchesObserve - ChildChanged: Decoding error: \(error)")
                }
            } withCancel: { error in
                Logger.multiplayer.error("LobbyMatchesObserve - ChildChanged: Firebase observer cancelled: \(error)")
                continuation.finish()
            }
            observationHandles.append(childChangedHandle)
            Logger.multiplayer.debug("LobbyMatchesObserve observing .childChanged events for lobby matches.")

            // --- CHILD REMOVED ---
            let childRemovedHandle = query.observe(.childRemoved) { snapshot in
                let removedMatchId = snapshot.key
                if let index = currentMatches.firstIndex(where: { $0.id == removedMatchId }) {
                    currentMatches.remove(at: index)
                    continuation.yield(currentMatches)
                } else {
                    Logger.multiplayer
                        .warning("LobbyMatchesObserve - ChildRemoved: Received match not found in local list")
                }
            } withCancel: { error in
                Logger.multiplayer.error("LobbyMatchesObserve - ChildRemoved: Firebase observer cancelled: \(error)")
                continuation.finish()
            }
            observationHandles.append(childRemovedHandle)
            Logger.multiplayer.debug("LobbyMatchesObserve observing .childRemoved events for waiting matches.")

            continuation.onTermination = { _ in
                query.removeObserver(withHandle: childAddedHandle)
                query.removeObserver(withHandle: childChangedHandle)
                query.removeObserver(withHandle: childRemovedHandle)
            }
        }
    }

    func joinMatch(_ match: Match) async throws {
        let playersRef = matchesRef.child(match.id).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        var currentPlayers: [User] = []
        if let value = playerSnapshot.value as? [Any] {
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                currentPlayers = try JSONDecoder().decode([User].self, from: data)
            } catch {
                throw ServerError.failedToDecode(underlyingError: error)
            }
        }

        guard !currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(self.user.id) is already in the match: \(match.id)")
            throw ServerError.playerAlreadyInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.append(user)

        let playersArray: Any
        do {
            let data = try JSONEncoder().encode(updatedPlayers)
            playersArray = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await playersRef.setValue(playersArray)
            self.match = match
            Logger.multiplayer.debug("User \(self.user.id) joined match: \(match.id)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for joining match: \(match.id), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func leaveMatch() async throws {
        guard let matchId = match?.id else {
            throw ServerError.matchNotSet
        }
        let playersRef = matchesRef.child(matchId).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        guard playerSnapshot.exists(), let snapshotValue = playerSnapshot.value else {
            throw ServerError.unexpectedDataFormat
        }

        var currentPlayers: [User] = []
        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue)
            currentPlayers = try JSONDecoder().decode([User].self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }

        guard currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(self.user.id) is not in the match: \(matchId)")
            throw ServerError.playerNotInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.removeAll { $0 == user }

        let playersArray: Any
        do {
            let data = try JSONEncoder().encode(updatedPlayers)
            playersArray = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }

        do {
            try await playersRef.setValue(playersArray)
            self.match = match
            Logger.multiplayer.debug("User \(self.user.id) left match: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for leaving match: \(matchId), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }
}
// swiftlint:enable type_body_length
