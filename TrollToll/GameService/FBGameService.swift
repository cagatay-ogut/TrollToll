//
//  FBGameService.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

import FirebaseDatabase
import OSLog
import SwiftUI

@Observable
class FBGameService: GameService {
    let dbRef: DatabaseReference
    let gamesRef: DatabaseReference

    init() {
        self.dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        self.gamesRef = dbRef.child("games")
    }

    func createGame(with gameState: GameState) async throws {
        let gameRef = gamesRef.child(gameState.matchId)

        let dictionary = try FBEncoder.encode(gameState)
        do {
            try await gameRef.setValue(dictionary)
            Logger.multiplayer.debug("Created game: \(gameState.matchId)")
        } catch {
            Logger.multiplayer.error("Could not create game: \(gameState.matchId), error: \(error)")
            throw ServerError.serverError(underlyingError: error)
        }
    }

    func fetchGame(with id: String) async throws -> GameState {
        let gameRef = gamesRef.child(id)

        let snapshot = try await withCheckedThrowingContinuation { continuation in
            gameRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: ServerError.serverCancel(underlyingError: error))
            }
        }

        return try FBDecoder.decode(GameState.self, from: snapshot)
    }

    func streamGame(of id: String) -> AsyncThrowingStream<GameState, Error> {
        AsyncThrowingStream { continuation in
            let gameRef = gamesRef.child(id)

            let handle = gameRef.observe(.value) { snapshot in
                do {
                    let gameState = try FBDecoder.decode(GameState.self, from: snapshot)
                    continuation.yield(gameState)
                } catch ServerError.unexpectedDataFormat {
                    continuation.finish() // game ended
                    return
                } catch {
                    continuation.finish(throwing: ServerError.failedToDecode(underlyingError: error))
                }
            } withCancel: { error in
                continuation.finish(throwing: ServerError.serverCancel(underlyingError: error))
            }

            continuation.onTermination = { _ in
                gameRef.removeObserver(withHandle: handle)
            }
        }
    }

    func updateGame(for gameId: String, with newGameState: GameState) async throws -> GameState {
        let gameRef = gamesRef.child(gameId)

        let (success, snapshot) = try await gameRef.runTransactionBlock { currentData in
            guard currentData.value is [String: Any] else {
                return TransactionResult.success(withValue: currentData)
            }

            do {
                currentData.value = try FBEncoder.encode(newGameState)
                return TransactionResult.success(withValue: currentData)
            } catch {
                Logger.multiplayer.error("Could not end player turn: \(error)")
                return TransactionResult.abort()
            }
        }

        guard success else {
            throw ServerError.failedToUpdateGameState
        }

        return try FBDecoder.decode(GameState.self, from: snapshot)
    }
}
