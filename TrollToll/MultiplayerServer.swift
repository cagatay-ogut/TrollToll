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
    var dbRef: DatabaseReference
    var authState: AuthenticationState = .unauthenticated
    var match: Match?
    var matches: [Match] = []

    init(isHost: Bool) {
        self.isHost = isHost

        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
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

    func hostMatch() async {
        guard let userId else { return }
        let matchRef = dbRef.child("matches").childByAutoId()
        guard let matchId = matchRef.key else { return }

        let match = Match(id: matchId, status: .waitingForPlayers, hostId: userId)
        do {
            let data = try JSONEncoder().encode(match)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let newMatchRef = try await matchRef.setValue(dict)
                Logger.multiplayer.debug("Create match: \(newMatchRef.key ?? "unknown key")")
            }
        } catch {
            Logger.multiplayer.error("Could not host match: \(error)")
        }
    }

    func findMatch() async {
        let matchesRef = dbRef.child("matches")

        self.matches = await withCheckedContinuation { continuation in
            matchesRef.observeSingleEvent(of: .value) { snapshot in
                guard let matchesDict = snapshot.value as? [String: [String: Any]] else {
                    continuation.resume(returning: [])
                    Logger.multiplayer.error("Error: Could not cast snapshot value to [String: [String: Any]]")
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
}
