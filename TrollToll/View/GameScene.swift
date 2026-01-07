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
                layoutGameState(with: viewModel.gameState)
            }
        }
    }

    private let cardSize = CGSize(width: 30, height: 50)
    private let padding: CGFloat = 20

    override func didChangeSize(_ oldSize: CGSize) {
        Logger.gameScene.debug("Changed size from: \(String(describing: oldSize)) to: \(String(describing: self.size))")
    }

    override func didMove(to view: SKView) {
        Logger.gameScene.debug("Did move")

        if let viewModel {
            layoutGameState(with: viewModel.gameState)
        }
    }

    func onStateChange() {
        guard let gameState = viewModel?.gameState else { return }
        layoutGameState(with: gameState)
    }

    private func layoutGameState(with gameState: GameState) {
        Logger.gameScene.debug("Setting game state")
        clearScene()

        layoutMiddleDeck(gameState.middleCards.count)
        layoutMiddleCard(gameState.middleCards.first ?? 0)
        layoutMiddleTokens(gameState.tokenInMiddle)
        layoutPlayerInfo(gameState.players)
        layoutPlayerTokens(gameState.playerTokens)
        layoutPlayerCards(gameState.playerCards)
    }

    private func clearScene() {
        removeAllChildren()
    }

    private func layoutMiddleDeck(_ cardCount: Int) {
        let middleDeck = DeckNode(
            cardCount: cardCount,
            position: size.center,
            size: cardSize
        )
        addChild(middleDeck)
    }

    private func layoutMiddleCard(_ cardNumber: Int) {
        let middleCard = CardNode(
            cardNumber: cardNumber,
            position: CGPoint(x: size.center.x, y: size.center.y - 10 - cardSize.height),
            size: cardSize
        )
        addChild(middleCard)
    }

    private func layoutMiddleTokens(_ tokenCount: Int) {
        let middleTokens = TokenNode(
            tokenCount: tokenCount,
            position: CGPoint(x: size.center.x, y: size.center.y + 10 + cardSize.height),
            radius: cardSize.width / 2
        )
        addChild(middleTokens)
    }

    private func layoutPlayerInfo(_ players: [User]) {
        for (index, player) in players.enumerated() {
            let playerPos = calculatePlayerPosition(index: index, total: players.count)
            // in portrait, put it under players
            // in landscape, put it left side for players in the left and put it right side for players in the right
            let xModifier = size.width < size.height ? 0.0 : playerPos.x < size.center.x ? -1.0 : 1.0
            let yModifier = size.width < size.height ? -1.0 : 0.0

            let nameNode = SKLabelNode(text: "\(player.name)")
            nameNode.horizontalAlignmentMode = .center
            nameNode.verticalAlignmentMode = .center
            nameNode.fontSize = 20
            nameNode.fontName! += "-Bold"
            nameNode.position = CGPoint(x: playerPos.x + 60 * xModifier, y: (playerPos.y + 50 * yModifier) + 10)

            let pointsNode = SKLabelNode(text: "points: \(viewModel?.point(for: player.id) ?? 0)")
            pointsNode.horizontalAlignmentMode = .center
            pointsNode.verticalAlignmentMode = .center
            pointsNode.fontSize = 20
            pointsNode.fontName! += "-Bold"
            pointsNode.position = CGPoint(x: playerPos.x + 60 * xModifier, y: (playerPos.y + 50 * yModifier) - 10)

            addChild(nameNode)
            addChild(pointsNode)
        }
    }

    private func layoutPlayerTokens(_ playerTokens: [String: Int]) {
        for (index, playerToken) in playerTokens.enumerated() {
            let token = TokenNode(
                tokenCount: playerToken.value,
                position: calculatePlayerPosition(index: index, total: playerTokens.count),
                radius: cardSize.width / 2
            )
            addChild(token)
        }
    }

    private func layoutPlayerCards(_ playerCards: [String: [Int]]) {
        for (index, cards) in playerCards.enumerated() {
            let playerPos = calculatePlayerPosition(index: index, total: playerCards.count)
            for (cardIndex, playerCard) in cards.value.enumerated() {
                // in portrait, put it above players
                // in landscape, put it below for players in upper side and put it above for players in down side
                let yModifier = size.width < size.height ? 1.0 : playerPos.y < size.center.y ? 1.0 : -1.0
                let card = CardNode(
                    cardNumber: playerCard,
                    position: CGPoint(
                        x: playerPos.x + (CGFloat(cardIndex) * (cardSize.width + 5)),
                        y: playerPos.y + cardSize.height * yModifier
                    ),
                    size: cardSize
                )

                addChild(card)
            }
        }
    }

    private func calculatePlayerPosition(index: Int, total: Int) -> CGPoint {
        let sizeAfterPadding = CGSize(width: size.width - 2 * padding, height: size.height - 2 * padding)
        let minSideLength = min(sizeAfterPadding.width, sizeAfterPadding.height)
        let radius = minSideLength / 2

        let startAngle: CGFloat = 3 / 2 * .pi  // 270 degree, bottom
        let angleChange: CGFloat = 2 * .pi / CGFloat(total)
        let playerAngle = startAngle - (CGFloat(index) * angleChange) // clockwise change

        return CGPoint(
            x: size.center.x + radius * cos(playerAngle),
            y: size.center.y + radius * sin(playerAngle)
        )
    }
}

#Preview {
    let host = User(id: "host_id", name: "host", isHost: true)
    let player1 = User(id: "player_id", name: "player", isHost: false)
    let player2 = User(id: "player_id_2", name: "player2", isHost: false)
    let match = Match(id: "match_id", status: .playing, host: host, players: [player1, player2], createdAt: Date())
    var gameState = GameState(from: match)
    gameState.playerCards = ["host_id": [23, 24, 25], "player_id": [12, 15], "player_id_2": [17]]
    return GameView(
        user: host,
        match: match,
        gameState: gameState
    )
}
