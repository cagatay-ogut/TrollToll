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
    func authenticate() async -> AuthenticationState {
        do {
            let result = try await Auth.auth().signInAnonymously()
            Logger.multiplayer.debug("Auth with id: \(result.user.uid)")
            return .authenticated(userId: result.user.uid)
        } catch {
            Logger.multiplayer.error("Could not auth: \(error)")
            return .failed
        }
    }
}
