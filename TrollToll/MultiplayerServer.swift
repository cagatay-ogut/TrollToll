//
//  MultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import OSLog
import SwiftUI

@Observable
class MultiplayerServer: NSObject, MultiplayerInterface {
    let isHost: Bool
    var authState: AuthenticationState = .unauthenticated
    var match: Match?

    init(isHost: Bool) {
        self.isHost = isHost
    }

    func authenticate() {}

    func findMatch() {}
}
