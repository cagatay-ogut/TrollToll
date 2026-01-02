//
//  MultiplayerServer.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import Foundation

protocol MultiplayerServer {
    var user: User { get }
    var match: Match? { get }
    var matches: [Match] { get }
    var readyToStart: Bool { get }

    // common
    func observeMatch() async throws
    func stopObservingMatch()
    // host
    func hostMatch() async throws
    func cancelMatch() async throws
    func startMatch() async throws
    // player
    func findMatches() async throws
    func joinMatch(_ match: Match) async throws
    func leaveMatch() async throws

    // game
    func endPlayerTurn() async throws
}

enum MultiplayerServerError: LocalizedError {
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
    case notCurrentPlayer

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
        case .notCurrentPlayer:
            "Not current player"
        }
    }
}
