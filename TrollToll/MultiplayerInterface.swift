//
//  MultiplayerInterface.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import GameKit

protocol MultiplayerInterface {
    var isHost: Bool { get }
    var authState: AuthenticationState { get set }
    var match: MatchData? { get }

    func authenticate()
    func findMatch()
}

enum AuthenticationState {
    case unauthenticated, authenticated, failed
}

struct MatchData: Equatable {}
