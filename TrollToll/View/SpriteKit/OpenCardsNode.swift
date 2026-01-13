//
//  OpenCardsNode.swift
//  TrollToll
//
//  Created by Cagatay on 11.01.2026.
//

import SpriteKit

class OpenCardsNode: SKSpriteNode {
    var cards: [Int]

    init(cards: [Int], playerPosition: CGPoint, size: CGSize, screenCenter: CGPoint) {
        self.cards = cards
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = playerPosition

        let groups = groupConsecutive(cards)

        let spacingBetweenGroups: CGFloat = 8
        let stackOffset: CGFloat = 6
        for (groupIndex, group) in groups.enumerated() {
            let xPos: CGFloat
            if groups.count.isMultiple(of: 2) {
                let middle = groups.count / 2
                let xOffset = groupIndex < middle ? groupIndex - middle + 1 : groupIndex - middle
                let initialOffset = (groupIndex < middle ? -1 : 1) * (size.width + spacingBetweenGroups) / 2
                xPos = CGFloat(xOffset) * (size.width + spacingBetweenGroups) + initialOffset
            } else { // odd
                let middle = groups.count / 2
                let xOffset = groupIndex - middle
                xPos = CGFloat(xOffset) * (size.width + spacingBetweenGroups)
            }

            for (cardIndex, card) in group.enumerated() {
                let cardNode = SKShapeNode(
                    rect: CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
                )
                cardNode.strokeColor = .black
                cardNode.fillColor = .purple
                cardNode.position = .init(x: xPos + CGFloat(cardIndex) * stackOffset, y: size.height)
                let middle = group.count / 2
                let xOffset = cardIndex - middle
                cardNode.zRotation = (-.pi / 6) * CGFloat(xOffset)
                let labelNode = SKLabelNode(text: "\(card)")
                labelNode.horizontalAlignmentMode = .left
                labelNode.verticalAlignmentMode = .top
                labelNode.position = .init(x: -size.width / 2, y: size.height / 2)
                labelNode.fontSize = 12
                labelNode.fontName! += "-Bold"

                cardNode.addChild(labelNode)
                self.addChild(cardNode)
            }
        }

        if playerPosition.x < screenCenter.x - 1 {
            self.zRotation = -.pi / 2
        } else if playerPosition.x > screenCenter.x + 1 {
            self.zRotation = .pi / 2
        } else if playerPosition.y > screenCenter.y + 1 {
            self.zRotation = .pi
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func groupConsecutive(_ numbers: [Int]) -> [[Int]] {
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
}
