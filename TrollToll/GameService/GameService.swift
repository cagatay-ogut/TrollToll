//
//  Game.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

protocol GameService {
    func endPlayerTurn(of user: User, in matchId: String) async throws -> Match
}
