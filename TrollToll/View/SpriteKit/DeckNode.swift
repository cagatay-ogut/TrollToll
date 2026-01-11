//
//  DeckNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class DeckNode: SKSpriteNode {
    var cardCount: Int {
        didSet {
            children.compactMap { $0 as? SKLabelNode }.first?.text = "\(cardCount)"
        }
    }

    init(cardCount: Int, position: CGPoint, size: CGSize) {
        self.cardCount = cardCount
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = position

        let shownCards = min(5, cardCount)

        for index in 0..<shownCards {
            let xPos = -size.width / 2 + CGFloat(index * 2)
            let yPos = -size.height / 2 + CGFloat(index * 2)
            let cardNode = SKShapeNode(
                rect: CGRect(origin: .init(x: xPos, y: yPos), size: size)
            )
            cardNode.fillColor = .brown
            cardNode.strokeColor = .black

            if cardCount > 5, index == shownCards - 1 {
                let labelNode = SKLabelNode(text: "\(cardCount)")
                labelNode.horizontalAlignmentMode = .right
                labelNode.verticalAlignmentMode = .top
                labelNode.position = .init(x: xPos + size.width, y: yPos + size.height)
                labelNode.fontSize = 10
                labelNode.fontName! += "-Bold"

                cardNode.addChild(labelNode)
            }
            self.addChild(cardNode)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
