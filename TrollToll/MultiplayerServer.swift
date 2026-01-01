//
//  MultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import FirebaseAuth
import FirebaseDatabase
import OSLog
import SwiftUI

@Observable
class MultiplayerServer: NSObject, MultiplayerInterface {
    let isHost: Bool
    var userId: String?
    let dbRef: DatabaseReference
    let matchesRef: DatabaseReference
    var authState: AuthenticationState = .unauthenticated
    var match: Match?
    var hostedMatchId: String?
    var joinedMatchId: String?
    var matches: [Match] = []

    init(isHost: Bool) {
        self.isHost = isHost

        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        matchesRef = dbRef.child("matches")
    }

    func authenticate() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            userId = result.user.uid
            authState = .authenticated
            Logger.multiplayer.debug("Auth with id: \(result.user.uid)")
        } catch {
            authState = .failed
            Logger.multiplayer.error("Could not auth: \(error)")
        }
    }

    func observeMatch() async {
        let matchId = hostedMatchId ?? joinedMatchId
        guard let matchId else { return }

        for try await matchData in matchStream(matchId: matchId) {
            match = matchData
            Logger.multiplayer.debug("Match updated: \(String(describing: matchData))")
        }
    }

    private func matchStream(matchId: String) -> AsyncStream<Match> {
        AsyncStream { continuation in
            let matchRef = matchesRef.child(matchId)

            let handle = matchRef.observe(.value) { snapshot in
                if snapshot.exists() {
                    if let matchDict = snapshot.value as? [String: Any] {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: matchDict)
                            let match = try JSONDecoder().decode(Match.self, from: data)
                            continuation.yield(match)
                        } catch {
                            continuation.finish()
                        }
                    } else {
                        continuation.finish()
                    }
                } else {
                    continuation.finish()
                }
            } withCancel: { _ in
                continuation.finish()
            }

            continuation.onTermination = { _ in
                matchRef.removeObserver(withHandle: handle)
            }
        }
    }

    func hostMatch() async {
        guard let userId else { return }
        let matchRef = matchesRef.childByAutoId()
        guard let matchId = matchRef.key else { return }

        let match = Match(id: matchId, status: .waitingForPlayers, hostId: userId)
        do {
            let data = try JSONEncoder().encode(match)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                try await matchRef.setValue(dict)
                hostedMatchId = matchId
                Logger.multiplayer.debug("Create match: \(matchId)")
            }
        } catch {
            Logger.multiplayer.error("Could not host match: \(error)")
        }
    }

    func cancelMatch() async {
        guard let matchId = hostedMatchId else { return }
        let matchRef = matchesRef.child(matchId)
        do {
            try await matchRef.removeValue()
        } catch {
            Logger.multiplayer.error("Could not delete match: \(matchId)")
        }
    }

    func findMatch() async {
        self.matches = await withCheckedContinuation { continuation in
            matchesRef.observeSingleEvent(of: .value) { snapshot in
                guard let matchesDict = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    Logger.multiplayer.error("Could not cast snapshot value to [String: [String: Any]]")
                    return
                }

                var matches: [Match] = []
                for (_, matchDict) in matchesDict {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: matchDict)
                        let match = try JSONDecoder().decode(Match.self, from: data)
                        matches.append(match)
                    } catch {
                        Logger.multiplayer.error("Could not decode Match: \(error)")
                    }
                }
                continuation.resume(returning: matches)
            }
        }
    }

    func joinMatch(with matchId: String) async {
        guard let userId else { return }
        let matchRef = matchesRef.child(matchId)
        let playerIdsRef = matchRef.child("playerIds")

        let playerSnapshot = await withCheckedContinuation { continuation in
            playerIdsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }

        var playerIds: [String] = []
        if let playersArray = playerSnapshot.value as? [String] {
            playerIds = playersArray
        }

        guard !playerIds.contains(userId) else {
            Logger.multiplayer.debug("User \(userId) is already in the game: \(matchId)")
            return
        }

        var updatedPlayerIds = playerIds
        updatedPlayerIds.append(userId)

        let updateData: [String: Any] = [
            "playerIds": updatedPlayerIds
        ]

        do {
            try await matchRef.updateChildValues(updateData)
            joinedMatchId = matchId
            Logger.multiplayer.debug("User joined game: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for joining match: \(matchId)")
        }
    }

    func leaveMatch() async {
        guard let matchId = joinedMatchId, let userId else { return }
        let matchRef = matchesRef.child(matchId)
        let playerIdsRef = matchRef.child("playerIds")

        let playerSnapshot = await withCheckedContinuation { continuation in
            playerIdsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
        var playerIds: [String] = playerSnapshot.value as? [String] ?? []
        guard playerIds.contains(userId) else { return }
        playerIds.removeAll { $0 == userId }

        let updateData: [String: Any] = [
            "playerIds": playerIds
        ]

        do {
            try await matchRef.updateChildValues(updateData)
            joinedMatchId = matchId
            Logger.multiplayer.debug("User left game: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for leaving match: \(matchId)")
        }
    }
}
