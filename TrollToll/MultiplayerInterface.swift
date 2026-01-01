//
//  MultiplayerInterface.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

protocol MultiplayerInterface {
    var isHost: Bool { get }
    var match: Match? { get }
    var matches: [Match] { get }
    var joinedMatchId: String? { get }
    var readyToStart: Bool { get }

    // common
    func observeMatch() async
    // host
    func hostMatch() async
    func cancelMatch() async
    func startMatch() async
    // player
    func findMatch() async
    func joinMatch(with matchId: String) async
    func leaveMatch() async
}
