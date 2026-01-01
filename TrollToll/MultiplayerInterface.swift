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
    var joinedMatchId: String? { get }

    // common
    func authenticate() async
    func observeMatch() async
    // host
    func hostMatch() async
    func cancelMatch() async
    // player
    func findMatch() async
    func joinMatch(with matchId: String) async
    func leaveMatch() async
}

enum AuthenticationState {
    case unauthenticated, authenticated, failed
}
