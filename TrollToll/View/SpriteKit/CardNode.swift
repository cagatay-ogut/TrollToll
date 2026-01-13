//
//  CardNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class CardNode: SKSpriteNode {
    var cardNumber: Int {
        didSet {
            children.compactMap { $0 as? SKLabelNode }.first?.text = "\(cardNumber)"
        }
    }

    init(cardNumber: Int, position: CGPoint, size: CGSize) {
        self.cardNumber = cardNumber
        super.init(texture: nil, color: UIColor.purple, size: size)
        self.position = position

        let borderNode = SKShapeNode(
            rect: CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
        )
        borderNode.strokeColor = .black
        let labelNode = SKLabelNode(text: "\(cardNumber)")
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .top
        labelNode.position = .init(x: -size.width / 2, y: size.height / 2)
        labelNode.fontSize = 12
        labelNode.fontName! += "-Bold"

        self.addChild(borderNode)
        self.addChild(labelNode)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
