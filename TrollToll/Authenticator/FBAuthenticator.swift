//
//  FBAuthenticator.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

import FirebaseAuth
import OSLog

@Observable
class FBAuthenticator: Authenticator {
    var authState: AuthenticationState = .unauthenticated

    func authenticate() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            authState = .authenticated(userId: result.user.uid)
            Logger.multiplayer.debug("Auth with id: \(result.user.uid)")
        } catch {
            authState = .failed
            Logger.multiplayer.error("Could not auth: \(error)")
        }
    }
}
