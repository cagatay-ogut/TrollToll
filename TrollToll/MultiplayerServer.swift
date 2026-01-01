//
//  MultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

protocol MultiplayerServer {
    var user: User { get }
    var match: Match? { get }
    var matches: [Match] { get }
    var readyToStart: Bool { get }

    // common
    func observeMatch() async
    // host
    func hostMatch() async
    func cancelMatch() async
    func startMatch() async
    // player
    func findMatch() async
    func joinMatch(_ match: Match) async
    func leaveMatch() async
}
