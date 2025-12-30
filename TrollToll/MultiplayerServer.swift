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
    var match: MatchData?
    private let localPlayer = GKLocalPlayer.local

    private var rootVC: UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }

    init(isHost: Bool) {
        self.isHost = isHost
    }

    func authenticate() {
        if localPlayer.isAuthenticated {
            authState = .authenticated
            return
        }

        localPlayer.authenticateHandler = { [self] vc, error in
            if let error {
                Logger.multiplayer.error("Could not authenticate: \(error)")
                authState = .failed
                return
            }

            if vc != nil { // can't find a case where vc is returned
                Logger.multiplayer.warning("Received vc, is authenticated: \(self.localPlayer.isAuthenticated)")
            }

            if localPlayer.isAuthenticated {
                authState = .authenticated
            } else {
                authState = .failed
            }
        }
    }

    func findMatch() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 5

        let vc = GKMatchmakerViewController(matchRequest: request)
        vc?.matchmakerDelegate = self
        rootVC?.present(vc!, animated: true)
    }
}

extension MultiplayerServer: GKMatchmakerViewControllerDelegate {
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        self.match = MatchData() // TODO: fill
        Logger.multiplayer.debug("Found match: \(match)")
    }

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        Logger.multiplayer.debug("Matchmaking was cancelled")
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error) {
        viewController.dismiss(animated: true)
        Logger.multiplayer.error("Failed to find a match: \(error)")
    }
}
