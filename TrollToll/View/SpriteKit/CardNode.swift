//
//  CardNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class CardNode: SKSpriteNode {
    private var cardNode: SKShapeNode
    private var labelNode: SKLabelNode

    var cardNumber: Int {
        didSet {
            if oldValue != cardNumber {
                updateCard()
            }
        }
    }

    init(cardNumber: Int, position: CGPoint, size: CGSize) {
        self.cardNumber = cardNumber
        self.labelNode = SKLabelNode(text: "\(cardNumber)")
        self.cardNode = SKShapeNode(
            rect: CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
        )
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = position

        cardNode.strokeColor = .black
        cardNode.fillColor = .purple
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .top
        labelNode.position = .init(x: -size.width / 2, y: size.height / 2)
        labelNode.fontSize = 12
        labelNode.fontName! += "-Bold"

        cardNode.addChild(labelNode)
        self.addChild(cardNode)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCard() {
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.3)
        let updateNumber = SKAction.run {
            self.labelNode.text = "\(self.cardNumber)"
        }
        let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.3)
        cardNode.run(SKAction.sequence([fadeOut, updateNumber, fadeIn]))
    }
}
