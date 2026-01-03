//
//  LobbyService.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import Foundation

protocol LobbyService {
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

enum ServerError: LocalizedError {
    case matchNotSet
    case noMatchFound
    case playerAlreadyInMatch
    case playerNotInMatch
    case failedToEncode(underlyingError: Error)
    case failedToDecode(underlyingError: Error)
    case serverCancel(underlyingError: Error)
    case serverFail
    case serverError(underlyingError: Error)
    case unexpectedDataFormat
    case failedToUpdateGameState

    var errorDescription: String? {
        switch self {
        case .matchNotSet:
            "Match not set"
        case .noMatchFound:
            "No match found"
        case .playerAlreadyInMatch:
            "Player already in the match"
        case .playerNotInMatch:
            "Player not in the match"
        case .failedToEncode(let underlyingError):
            "Failed to encode: \(underlyingError)"
        case .failedToDecode(let underlyingError):
            "Failed to decode: \(underlyingError)"
        case .serverCancel(let underlyingError):
            "Server cancelled: \(underlyingError)"
        case .serverFail:
            "Server failed"
        case .serverError(let underlyingError):
            "Server error: \(underlyingError)"
        case .unexpectedDataFormat:
            "Unexpected data format"
        case .failedToUpdateGameState:
            "Failed to update game state"
        }
    }
}
