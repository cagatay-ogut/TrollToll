//
//  MultiplayerInterface.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

protocol MultiplayerInterface {
    var isHost: Bool { get }
    var authState: AuthenticationState { get set }

    func authenticate()
}

enum AuthenticationState {
    case unauthenticated, authenticated, failed
}
