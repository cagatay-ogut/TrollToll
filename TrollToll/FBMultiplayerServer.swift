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

    func observeMatch() async {
        guard let matchId = match?.id else { return }

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
        let matchRef = matchesRef.childByAutoId()
        guard let matchId = matchRef.key else { return }

        let match = Match(id: matchId, status: .waitingForPlayers, host: user)
        do {
            let data = try JSONEncoder().encode(match)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                try await matchRef.setValue(dict)
                self.match = match
                Logger.multiplayer.debug("Create match: \(matchId)")
            }
        } catch {
            Logger.multiplayer.error("Could not host match: \(error)")
        }
    }

    func cancelMatch() async {
        guard let matchId = match?.id else { return }
        let matchRef = matchesRef.child(matchId)
        do {
            try await matchRef.removeValue()
        } catch {
            Logger.multiplayer.error("Could not delete match: \(matchId)")
        }
    }

    func startMatch() async {
        guard let matchId = match?.id else { return }
        let matchRef = matchesRef.child(matchId)

        let updateData: [String: Any] = [
            "status": MatchStatus.playing.rawValue
        ]
        do {
            try await matchRef.updateChildValues(updateData)
            Logger.multiplayer.debug("Host started game: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update status when starting match: \(matchId)")
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

    func joinMatch(_ match: Match) async {
        let matchRef = matchesRef.child(match.id)
        let playersRef = matchRef.child("players")

        let playerSnapshot = await withCheckedContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }

        var players: [User] = []
        if let playersArray = playerSnapshot.value as? [User] {
            players = playersArray
        }

        guard !players.contains(user) else {
            Logger.multiplayer.debug("User \(self.user.id) is already in the game: \(match.id)")
            return
        }

        var updatedPlayers = players
        updatedPlayers.append(user)

        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(updatedPlayers)
            guard let encodedData = try JSONSerialization.jsonObject(with: jsonData) as? [Any] else {
                throw NSError(
                        domain: "Conversion",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert encoded JSON data to dictionary."]
                    )
            }

            try await playersRef.setValue(encodedData)
            self.match = match
            Logger.multiplayer.debug("User joined game: \(match.id)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for joining match: \(match.id), error: \(error)")
        }
    }

    func leaveMatch() async {
        guard let matchId = match?.id else { return }
        let matchRef = matchesRef.child(matchId)
        let playersRef = matchRef.child("players")

        let playerSnapshot = await withCheckedContinuation { continuation in
            playersRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }

        guard let snapshotValue = playerSnapshot.value else { return }

        do {
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: snapshotValue, options: [])
            var players = try decoder.decode([User].self, from: data)

            guard players.contains(user) else { return }
            players.removeAll { $0 == user }

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(players)
            guard let encodedData = try JSONSerialization.jsonObject(with: jsonData) as? [Any] else {
                throw NSError(
                        domain: "Conversion",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert encoded JSON data to dictionary."]
                    )
            }

            try await playersRef.setValue(encodedData)
            self.match = match
            Logger.multiplayer.debug("User left game: \(matchId)")
        } catch {
            Logger.multiplayer.error("Could not update player ids for leaving match: \(matchId)")
        }
    }
}
