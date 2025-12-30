//
//  MultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import GameKit
import OSLog
import SwiftUI

@Observable
class MultiplayerServer: NSObject, MultiplayerInterface {
    let isHost: Bool
    var authState: AuthenticationState = .unauthenticated
    private let localPlayer = GKLocalPlayer.local

    init(isHost: Bool) {
        self.isHost = isHost
    }

    func authenticate() {
        localPlayer.authenticateHandler = { [self] vc, error in
            if let error {
                Logger.multiplayer.error("Could not authenticate: \(error)")
                authState = .failed
                return
            }

            if let vc { // can't find a case where vc is returned
                Logger.multiplayer.warning("Received vc, is authenticated: \(self.localPlayer.isAuthenticated)")
            }

            if localPlayer.isAuthenticated {
                authState = .authenticated
            } else {
                authState = .failed
            }
        }
    }
}
