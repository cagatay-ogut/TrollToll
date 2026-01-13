//
//  GameScene.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import OSLog
import SpriteKit
import SwiftUI

class GameScene: SKScene {
    var viewModel: GameViewModel? {
        didSet {
            if let viewModel {
                layoutGameState(with: viewModel.gameState, for: viewModel.user)
            }
        }
    }

    private let cardSize = CGSize(width: 30, height: 50)
    private let tokenRadius: CGFloat = 10
    private let padding: CGFloat = 70

    override func didChangeSize(_ oldSize: CGSize) {
        Logger.gameScene.debug("Changed size from: \(String(describing: oldSize)) to: \(String(describing: self.size))")
    }

    override func didMove(to view: SKView) {
        Logger.gameScene.debug("Did move")

        if let viewModel {
            layoutGameState(with: viewModel.gameState, for: viewModel.user)
        }
    }

    func onStateChange() {
        guard let gameState = viewModel?.gameState, let user = viewModel?.user else { return }
        layoutGameState(with: gameState, for: user)
    }

    private func layoutGameState(with gameState: GameState, for user: User) {
        Logger.gameScene.debug("Setting game state")
        clearScene()

        layoutMiddleDeck(gameState.middleCards.count)
        layoutMiddleCard(gameState.middleCards.first ?? 0)
        layoutMiddleTokens(gameState.tokenInMiddle)
        layoutPlayerInfo(gameState.players, userId: user.id)
        layoutPlayerTokens(gameState.playerTokens, playerIds: gameState.players.map { $0.id }, userId: user.id)
        layoutPlayerCards(gameState.playerCards, playerIds: gameState.players.map { $0.id }, userId: user.id)
    }

    private func clearScene() {
        removeAllChildren()
    }

    private func layoutMiddleDeck(_ cardCount: Int) {
        let middleDeck = DeckNode(
            cardCount: cardCount,
            position: .init(x: size.width - cardSize.width - 10, y: cardSize.height / 2 + 10),
            size: cardSize
        )
        addChild(middleDeck)
    }

    private func layoutMiddleCard(_ cardNumber: Int) {
        let middleCard = CardNode(
            cardNumber: cardNumber,
            position: size.center,
            size: cardSize
        )
        addChild(middleCard)
    }

    private func layoutMiddleTokens(_ tokenCount: Int) {
        let middleTokens = TokenNode(
            tokenCount: tokenCount,
            position: size.center,
            radius: tokenRadius
        )
        addChild(middleTokens)
    }

    private func layoutPlayerInfo(_ players: [User], userId: String) {
        for player in players {
            let playerPos = calculatePlayerPosition(
                playerId: player.id,
                playerIds: players.map { $0.id },
                userId: userId
            )

            let playerInfoNode = PlayerInfoNode(
                playerName: player.name,
                point: viewModel?.point(for: player.id) ?? 0,
                position: playerPos,
                screenCenter: size.center
            )
            addChild(playerInfoNode)
        }
    }

    private func layoutPlayerTokens(_ playerTokens: [String: Int], playerIds: [String], userId: String) {
        for playerToken in playerTokens {
            let token = TokenNode(
                tokenCount: playerToken.value,
                position: calculatePlayerPosition(playerId: playerToken.key, playerIds: playerIds, userId: userId),
                radius: tokenRadius
            )
            addChild(token)
        }
    }

    private func layoutPlayerCards(_ playersCards: [String: [Int]], playerIds: [String], userId: String) {
        for playerCards in playersCards {
            let playerPos = calculatePlayerPosition(playerId: playerCards.key, playerIds: playerIds, userId: userId)
            let openCardsNode = OpenCardsNode(
                cards: playerCards.value,
                playerPosition: playerPos,
                size: cardSize,
                screenCenter: size.center
            )
            addChild(openCardsNode)
        }
    }

    private func calculatePlayerPosition(playerId: String, playerIds: [String], userId: String) -> CGPoint {
        guard let playerIndex = playerIds.firstIndex(of: playerId),
              let userIndex = playerIds.firstIndex(of: userId) else {
            return .zero
        }
        // always show user itself as first
        let shiftedIndex = (playerIndex - userIndex + playerIds.count) % playerIds.count

        let sizeAfterPadding = CGSize(width: size.width - 2 * padding, height: size.height - 2 * padding)
        let minSideLength = min(sizeAfterPadding.width, sizeAfterPadding.height)
        let radius = minSideLength / 2

        //  0 degree is right in iOS, and angle increases counter-clockwise
        let startAngle: CGFloat = 3 / 2 * .pi  // 270 degree -> bottom
        let angleChange: CGFloat = 2 * .pi / CGFloat(playerIds.count)
        let playerAngle = startAngle - (CGFloat(shiftedIndex) * angleChange) // clockwise change
        return CGPoint(
            x: size.center.x + radius * cos(playerAngle),
            y: size.center.y + radius * sin(playerAngle)
        )
    }
}

#if DEBUG
#Preview {
    let host = User(id: "host_id", name: "host", isHost: true)
    let player1 = User(id: "player_id", name: "player", isHost: false)
    let player2 = User(id: "player_id_2", name: "player2", isHost: false)
    let player3 = User(id: "player_id_3", name: "player3", isHost: false)
    let match = Match(
        id: "match_id",
        status: .playing,
        host: host,
        players: [player1, player2, player3],
        createdAt: Date()
    )
    var gameState = GameState(from: match)
    gameState.playerCards = [
        "host_id": [22, 23, 24, 28],
        "player_id": [12, 13, 15],
        "player_id_2": [15, 17, 19],
        "player_id_3": [3, 6]
    ]
    return GameView(
        user: host,
        match: match,
        gameState: gameState
    )
}
#endif
