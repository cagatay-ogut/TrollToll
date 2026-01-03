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
    let matchesRef: DatabaseReference

    init() {
        self.dbRef = Database
            .database(url: "https://trolltoll-ee309-default-rtdb.europe-west1.firebasedatabase.app")
            .reference()
        self.matchesRef = dbRef.child("matches")
    }

    func endPlayerTurn(of user: User, in matchId: String) async throws -> Match {
        let matchRef = matchesRef.child(matchId)

        let (success, snapshot) = try await matchRef.runTransactionBlock { currentData in
            guard let value = currentData.value else {
                return TransactionResult.abort()
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                var match = try JSONDecoder().decode(Match.self, from: data)

                guard match.state.currentPlayerId == user.id else {
                    return TransactionResult.abort()
                }

                let currentPlayers = [match.host] + match.players
                guard let currentPlayerIndex = currentPlayers.firstIndex(of: user) else {
                    return TransactionResult.abort()
                }
                if currentPlayerIndex + 1 == currentPlayers.count {
                    match.state.currentPlayerId = currentPlayers[0].id
                    match.state.turn += 1
                } else {
                    match.state.currentPlayerId = currentPlayers[currentPlayerIndex + 1].id
                }

                let updatedData = try JSONEncoder().encode(match)
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
            return try JSONDecoder().decode(Match.self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }
    }
}
