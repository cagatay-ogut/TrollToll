//
//  Game.swift
//  TrollToll
//
//  Created by Cagatay on 2.01.2026.
//

protocol GameService {
    func createGame(with gameState: GameState) async throws
    func fetchGame(with id: String) async throws -> GameState
    func streamGame(of id: String) async throws -> AsyncThrowingStream<GameState, Error>
    func updateGame(for gameId: String, with newGameState: GameState) async throws -> GameState
}
