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
    var viewModel: GameViewModel?

    static let animDuration: TimeInterval = 0.6
    private let cardSize = CGSize(width: 30, height: 50)
    private let tokenRadius: CGFloat = 10
    private let padding: CGFloat = 70

    private var deckNode: DeckNode?
    private var middleCardNode: MiddleCardNode?
    private var middleTokensNode: MiddleTokensNode?
    private var playerTokensNodes: [String: PlayerTokensNode] = [:]
    private var playerCardsNodes: [String: OpenCardsNode] = [:]
    private var playerInfoNodes: [String: PlayerInfoNode] = [:]

    override func didChangeSize(_ oldSize: CGSize) {
        Logger.gameScene.debug("Changed size from: \(String(describing: oldSize)) to: \(String(describing: self.size))")
    }

    override func didMove(to view: SKView) {
        Logger.gameScene.debug("Did move")

        if let viewModel {
            clearScene()
            layoutGameState(with: viewModel.gameState, for: viewModel.user, lastPlayerPos: nil)
        }
    }

    func onStateChange() {
        Logger.gameScene.debug("On state change")
        guard let gameState = viewModel?.gameState, let user = viewModel?.user else { return }
        var lastPlayerPos: CGPoint?
        if let lastPlayerId = viewModel?.lastPlayerId {
            lastPlayerPos = calculatePlayerPosition(
                playerId: lastPlayerId,
                playerIds: gameState.players.map { $0.id },
                userId: user.id
            )
        }
        layoutGameState(with: gameState, for: user, lastPlayerPos: lastPlayerPos)
    }

    private func layoutGameState(with gameState: GameState, for user: User, lastPlayerPos: CGPoint?) {
        Logger.gameScene.debug("Setting game state")

        layoutDeck(gameState.deckCards.count)
        layoutMiddleCard(gameState.deckCards.first ?? 0, lastPlayerPos: lastPlayerPos)
        layoutMiddleTokens(gameState.tokenInMiddle, lastPlayerPos: lastPlayerPos)
        layoutPlayerTokens(gameState.playerTokens, playerIds: gameState.players.map { $0.id }, userId: user.id)
        layoutPlayerCards(gameState.playerCards, playerIds: gameState.players.map { $0.id }, userId: user.id)
        layoutPlayerInfos(gameState.players, userId: user.id)
    }

    private func clearScene() {
        removeAllChildren()
    }

    private func layoutDeck(_ cardCount: Int) {
        if let deckNode {
            deckNode.cardCount = cardCount
        } else {
            deckNode = DeckNode(
                cardCount: cardCount,
                position: .init(x: size.width - cardSize.width - 10, y: cardSize.height / 2 + 20),
                size: cardSize
            )
            addChild(deckNode!)
        }
    }

    private func layoutMiddleCard(_ cardNumber: Int, lastPlayerPos: CGPoint?) {
        if let middleCardNode {
            middleCardNode.updateCard(cardNumber, lastPlayerPos: lastPlayerPos)
        } else {
            middleCardNode = MiddleCardNode(
                cardNumber: cardNumber,
                position: size.center,
                size: cardSize
            )
            addChild(middleCardNode!)
        }
    }

    private func layoutMiddleTokens(_ tokenCount: Int, lastPlayerPos: CGPoint?) {
        if let middleTokensNode {
            middleTokensNode.updateTokens(newTokenCount: tokenCount, movePos: lastPlayerPos)
        } else {
            middleTokensNode = MiddleTokensNode(
                tokenCount: tokenCount,
                position: size.center,
                radius: tokenRadius
            )
            addChild(middleTokensNode!)
        }
    }

    private func layoutPlayerTokens(_ playerTokens: [String: Int], playerIds: [String], userId: String) {
        for playerToken in playerTokens {
            if let tokenNode = playerTokensNodes[playerToken.key] {
                tokenNode.updateTokens(newTokenCount: playerToken.value, movePos: size.center)
            } else {
                playerTokensNodes[playerToken.key] = PlayerTokensNode(
                    tokenCount: playerToken.value,
                    position: calculatePlayerPosition(playerId: playerToken.key, playerIds: playerIds, userId: userId),
                    radius: tokenRadius
                )
                addChild(playerTokensNodes[playerToken.key]!)
            }
        }
    }

    private func layoutPlayerCards(_ playersCards: [String: [Int]], playerIds: [String], userId: String) {
        for playerCards in playersCards {
            if let playerCardNode = playerCardsNodes[playerCards.key] {
                playerCardNode.cards = playerCards.value
            } else {
                let playerPos = calculatePlayerPosition(playerId: playerCards.key, playerIds: playerIds, userId: userId)

                playerCardsNodes[playerCards.key] = OpenCardsNode(
                    cards: playerCards.value,
                    playerPosition: playerPos,
                    size: cardSize,
                    screenCenter: size.center
                )
                addChild(playerCardsNodes[playerCards.key]!)
            }
        }
    }

    private func layoutPlayerInfos(_ players: [User], userId: String) {
        for player in players {
            if let playerInfoNode = playerInfoNodes[player.id] {
                playerInfoNode.point = viewModel?.point(for: player.id) ?? 0
            } else {
                let playerPos = calculatePlayerPosition(
                    playerId: player.id,
                    playerIds: players.map { $0.id },
                    userId: userId
                )

                playerInfoNodes[player.id] = PlayerInfoNode(
                    playerName: player.name,
                    point: viewModel?.point(for: player.id) ?? 0,
                    position: playerPos,
                    screenCenter: size.center
                )
                addChild(playerInfoNodes[player.id]!)
            }
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
