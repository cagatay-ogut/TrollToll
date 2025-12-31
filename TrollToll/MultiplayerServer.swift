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
    var hostedMatchId: String?
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
                try await matchRef.setValue(dict)
                hostedMatchId = matchId
                Logger.multiplayer.debug("Create match: \(matchId)")
            }
        } catch {
            Logger.multiplayer.error("Could not host match: \(error)")
        }
    }

    func cancelHosting() async {
        guard let matchId = hostedMatchId else { return }
        let matchesRef = dbRef.child("matches")
        let matchRef = matchesRef.child(matchId)
        do {
            try await matchRef.removeValue()
        } catch {
            Logger.multiplayer.error("Could not delete match: \(matchId)")
        }
    }

    func findMatch() async {
        self.matches = await withCheckedContinuation { continuation in
            let matchesRef = dbRef.child("matches")
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
}
