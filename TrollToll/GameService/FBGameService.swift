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

        let dictionary: [String: Any]
        do {
            let data = try JSONEncoder().encode(gameState)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ServerError.unexpectedDataFormat
            }
            dictionary = dict
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }

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

        guard snapshot.exists(), let snapshotValue = snapshot.value else {
            throw ServerError.unexpectedDataFormat
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue, options: [])
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }
    }

    func streamGame(of id: String) -> AsyncThrowingStream<GameState, Error> {
        AsyncThrowingStream { continuation in
            let gameRef = gamesRef.child(id)

            let handle = gameRef.observe(.value) { snapshot in
                do {
                    guard snapshot.exists(), let value = snapshot.value else {
                        continuation.finish() // game ended
                        return
                    }
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let gameState = try JSONDecoder().decode(GameState.self, from: data)
                    continuation.yield(gameState)
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

    func endPlayerTurn(of user: User, in gameId: String) async throws -> GameState {
        let gameRef = gamesRef.child(gameId)

        let (success, snapshot) = try await gameRef.runTransactionBlock { currentData in
            guard let value = currentData.value as? [String: Any] else {
                return TransactionResult.success(withValue: currentData)
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                var gameState = try JSONDecoder().decode(GameState.self, from: data)

                guard gameState.currentPlayerId == user.id else {
                    return TransactionResult.abort()
                }

                guard let currentPlayerIndex = gameState.players.firstIndex(of: user) else {
                    return TransactionResult.abort()
                }
                if currentPlayerIndex + 1 == gameState.players.count {
                    gameState.currentPlayerId = gameState.players[0].id
                    gameState.turn += 1
                } else {
                    gameState.currentPlayerId = gameState.players[currentPlayerIndex + 1].id
                }

                let updatedData = try JSONEncoder().encode(gameState)
                let dict = try JSONSerialization.jsonObject(with: updatedData)
                currentData.value = dict

                return TransactionResult.success(withValue: currentData)
            } catch {
                Logger.multiplayer.error("Could not end player turn: \(error)")
                return TransactionResult.abort()
            }
        }

        guard success else {
            throw ServerError.notCurrentPlayer
        }

        guard snapshot.exists(), let snapshotValue = snapshot.value else {
            throw ServerError.unexpectedDataFormat
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue)
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }
    }
}
