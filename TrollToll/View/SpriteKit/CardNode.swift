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
    private var cardNumber: Int {
        didSet {
            labelNode.text = "\(cardNumber)"
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

    func updateCard(_ cardNumber: Int, lastPlayerPos: CGPoint?) {
        guard cardNumber != self.cardNumber else { return }
        guard let lastPlayerPos else {
            self.cardNumber = cardNumber
            return
        }

        // move old card to last player position, then set new card in original position
        let initialPos = position
        let convertedPos = parent!.convert(lastPlayerPos, from: scene!)
        self.run(SKAction.move(to: convertedPos, duration: 0.6)) {
            self.cardNumber = cardNumber
            self.position = initialPos
        }
    }
}
