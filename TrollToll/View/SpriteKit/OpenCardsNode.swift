//
//  OpenCardsNode.swift
//  TrollToll
//
//  Created by Cagatay on 11.01.2026.
//

import SpriteKit

class OpenCardsNode: SKSpriteNode {
    private let screenCenter: CGPoint
    private let playerPosition: CGPoint

    private var cards: [Int] {
        didSet {
            layoutCards()
        }
    }

    init(cards: [Int], playerPosition: CGPoint, size: CGSize, screenCenter: CGPoint) {
        self.cards = cards
        self.screenCenter = screenCenter
        self.playerPosition = playerPosition
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = playerPosition

        layoutCards()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func groupConsecutive(_ numbers: [Int]) -> [[Int]] {
        guard !numbers.isEmpty else { return [] }

        var result: [[Int]] = []
        var currentGroup: [Int] = [numbers[0]]

        for index in 1..<numbers.count {
            let current = numbers[index]
            let previous = numbers[index - 1]

            if current == previous + 1 {
                currentGroup.append(current)
            } else {
                result.append(currentGroup)
                currentGroup = [current]
            }
        }

        result.append(currentGroup)
        return result
    }

    func updateCards(with newCards: [Int]) {
        guard cards != newCards else { return }
        run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0, duration: GameScene.animDuration / 2),
            SKAction.run { self.removeAllChildren() },
            SKAction.fadeAlpha(to: 1, duration: GameScene.animDuration / 2),
            SKAction.run { self.cards = newCards }
        ]))
    }

    private func layoutCards() {
        let groups = groupConsecutive(cards)

        let spacingBetweenGroups: CGFloat = 12
        let stackOffset: CGFloat = 8
        let totalCardCount = cards.count
        var totalCountInGroups = 0
        for (groupIndex, group) in groups.enumerated() {
            let xPos: CGFloat
            let middle = groups.count / 2
            if groups.count.isMultiple(of: 2) {
                let xOffset = groupIndex < middle ? groupIndex - middle + 1 : groupIndex - middle
                let initialOffset = (groupIndex < middle ? -1 : 1) * (size.width + spacingBetweenGroups) / 2
                xPos = CGFloat(xOffset) * (size.width + spacingBetweenGroups) + initialOffset
            } else { // odd
                let xOffset = groupIndex - middle
                xPos = CGFloat(xOffset) * (size.width + spacingBetweenGroups)
            }

            for (cardIndex, card) in group.enumerated() {
                let cardNode = SKShapeNode(
                    rect: CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
                )
                cardNode.strokeColor = .black
                cardNode.fillColor = .purple
                let middleInGroup = group.count / 2
                let xOffset = cardIndex - middleInGroup
                cardNode.position = .init(x: xPos + CGFloat(xOffset) * stackOffset, y: size.height)
                cardNode.zPosition = CGFloat(totalCardCount - totalCountInGroups - cardIndex)
                cardNode.zRotation = (-.pi / 8) * CGFloat(xOffset)
                let labelNode = SKLabelNode(text: "\(card)")
                labelNode.horizontalAlignmentMode = .right
                labelNode.verticalAlignmentMode = .top
                labelNode.position = .init(x: size.width / 2, y: size.height / 2)
                labelNode.fontSize = 12
                labelNode.fontName! += "-Bold"

                cardNode.addChild(labelNode)
                self.addChild(cardNode)
            }
            totalCountInGroups += group.count
        }

        self.zRotation = SceneCoordination
            .rotationAndPositionOfCard(for: playerPosition, basedOn: screenCenter, offset: .zero).rotation
    }
}
