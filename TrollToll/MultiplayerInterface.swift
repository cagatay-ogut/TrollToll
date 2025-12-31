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
    var matches: [Match] { get }

    func authenticate() async
    func hostMatch() async
    func cancelHosting() async
    func findMatch() async
}

enum AuthenticationState {
    case unauthenticated, authenticated, failed
}
