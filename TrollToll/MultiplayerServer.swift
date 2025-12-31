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
    var hostId: String?
    var dbRef: DatabaseReference
    var authState: AuthenticationState = .unauthenticated
    var match: Match?

    init(isHost: Bool) {
        self.isHost = isHost

        dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
    }

    func authenticate() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            hostId = result.user.uid
            authState = .authenticated
            Logger.multiplayer.debug("Auth with id: \(result.user.uid)")
        } catch {
            authState = .failed
            Logger.multiplayer.error("Could not auth: \(error)")
        }
    }

    func hostMatch() async {
        guard let hostId else { return }
        let matchRef = dbRef.child("matches").childByAutoId()
        let match = Match(status: .waitingForPlayers, hostId: hostId, playerIds: [], createdAt: Date())
        do {
            let data = try JSONEncoder().encode(match)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let newMatchRef = try await matchRef.setValue(dict!)
            print("new match id: \(newMatchRef.key!)")
        } catch {
            Logger.multiplayer.error("Could not host match: \(error)")
        }
    }

    func findMatch() {}
}
