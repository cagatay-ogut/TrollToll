//
//  Game.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

protocol GameService {
    var user: User { get }
    var match: Match { get }

    func endPlayerTurn() async throws
}
