//
//  LobbyRepo.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import Foundation

protocol LobbyRepo {
    // common
    func fetchMatch(of id: String) async throws -> Match
    func streamMatch(of id: String) async throws -> AsyncThrowingStream<Match, Error>
    // host
    func hostMatch(with user: User) async throws -> Match
    func cancelMatch(of id: String) async throws
    func startMatch(of id: String) async throws
    // player
    func streamLobbyMatches() async -> AsyncStream<[Match]>
    func joinMatch(_ match: Match, with user: User) async throws
    func leaveMatch(of id: String, with user: User) async throws
}
