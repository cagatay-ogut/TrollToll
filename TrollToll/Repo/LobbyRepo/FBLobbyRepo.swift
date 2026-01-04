//
//  FBLobbyRepo.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import FirebaseDatabase
import OSLog
import SwiftUI

@Observable
class FBLobbyRepo: LobbyRepo {
    let dbRef: DatabaseReference
    let matchesRef: DatabaseReference

    init() {
        self.dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        self.matchesRef = dbRef.child("matches")
    }

    func fetchMatch(of id: String) async throws -> Match {
        let matchRef = matchesRef.child(id)

        let snapshot = try await withCheckedThrowingContinuation { continuation in
            matchRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        return try FBDecoder.decode(Match.self, from: snapshot)
    }

    func streamMatch(of id: String) -> AsyncThrowingStream<Match, Error> {
        AsyncThrowingStream { continuation in
            let matchRef = matchesRef.child(id)

            let handle = matchRef.observe(.value) { snapshot in
                do {
                    let match = try FBDecoder.decode(Match.self, from: snapshot)
                    continuation.yield(match)
                } catch ServerError.unexpectedDataFormat {
                    continuation.finish() // match ended
                    return
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

    func hostMatch(with user: User) async throws -> Match {
        let matchRef = matchesRef.childByAutoId()
        guard let matchId = matchRef.key else {
            throw ServerError.serverFail
        }

        let match = Match(id: matchId, status: .waitingForPlayers, host: user)
        let dictionary = try FBEncoder.encode(match)

        do {
            try await matchRef.setValue(dictionary)
            Logger.multiplayer.debug("Created match: \(matchId)")
            return match
        } catch {
            Logger.multiplayer.error("Could not host match: \(matchId), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func cancelMatch(of id: String) async throws {
        let matchRef = matchesRef.child(id)
        do {
            try await matchRef.removeValue()
            Logger.multiplayer.debug("Deleted match: \(id)")
        } catch {
            Logger.multiplayer.error("Could not delete match: \(id), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func startMatch(of id: String) async throws {
        let matchRef = matchesRef.child(id)
        let updateData: [String: Any] = [
            "status": MatchStatus.playing.rawValue
        ]
        do {
            try await matchRef.updateChildValues(updateData)
            Logger.multiplayer.debug("Host started match: \(id)")
        } catch {
            Logger.multiplayer.error("Could not update status when starting match: \(id)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    // swiftlint:disable:next function_body_length
    func streamLobbyMatches() -> AsyncStream<[Match]> {
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
                    let newMatch = try FBDecoder.decode(Match.self, from: snapshot)
                    currentMatches.append(newMatch)
                    continuation.yield(currentMatches)
                } catch ServerError.unexpectedDataFormat {
                    Logger.multiplayer.error("LobbyMatchesObserve - ChildAdded: Snapshot does not have value")
                    return
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
                    let updatedMatch = try FBDecoder.decode(Match.self, from: snapshot)
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
                } catch ServerError.unexpectedDataFormat {
                    Logger.multiplayer.error("LobbyMatchesObserve - ChildAdded: Snapshot does not have value")
                    return
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

    func joinMatch(_ match: Match, with user: User) async throws {
        let playersRef = matchesRef.child(match.id).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        let currentPlayers: [User] = try FBDecoder.decodeArray([User].self, from: playerSnapshot)
        guard !currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(user.id) is already in the match: \(match.id)")
            throw ServerError.playerAlreadyInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.append(user)

        let playersArray = try FBEncoder.encodeArray(updatedPlayers)
        do {
            try await playersRef.setValue(playersArray)
            Logger.multiplayer.debug("User \(user.id) joined match: \(match.id)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for joining match: \(match.id), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func leaveMatch(of id: String, with user: User) async throws {
        let playersRef = matchesRef.child(id).child("players")

        let playerSnapshot = try await withCheckedThrowingContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        let currentPlayers = try FBDecoder.decodeArray([User].self, from: playerSnapshot)
        guard currentPlayers.contains(user) else {
            Logger.multiplayer.error("User \(user.id) is not in the match: \(id)")
            throw ServerError.playerNotInMatch
        }

        var updatedPlayers = currentPlayers
        updatedPlayers.removeAll { $0 == user }

        let playersArray = try FBEncoder.encodeArray(updatedPlayers)
        do {
            try await playersRef.setValue(playersArray)
            Logger.multiplayer.debug("User \(user.id) left match: \(id)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for leaving match: \(id), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }
}
