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
        super.init(texture: nil, color: UIColor.red, size: size)
        self.position = position

        let borderNode = SKShapeNode(
            rect: CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
        )
        borderNode.strokeColor = .black
        let labelNode = SKLabelNode(text: "\(cardCount)")
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.fontSize = 20
        labelNode.fontName! += "-Bold"

        self.addChild(borderNode)
        self.addChild(labelNode)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
