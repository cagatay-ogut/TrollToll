//
//  MultiplayerInterface.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

protocol MultiplayerInterface {
    var isHost: Bool { get }
    var authState: AuthenticationState { get set }
    var match: Match? { get }

    func authenticate()
    func findMatch()
}

enum AuthenticationState {
    case unauthenticated, authenticated, failed
}

struct Match: Equatable {}
