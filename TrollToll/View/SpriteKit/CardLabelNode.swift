//
//  CardLabelNode.swift
//  TrollToll
//
//  Created by Cagatay on 17.01.2026.
//

import SpriteKit

class CardLabelNode: SKNode {
    private let labelNode: SKLabelNode

    var text: String {
        didSet {
            labelNode.text = text
        }
    }

    init(text: String) {
        self.text = text
        self.labelNode = SKLabelNode(text: text)
        super.init()

        labelNode.verticalAlignmentMode = .top
        labelNode.horizontalAlignmentMode = .right
        labelNode.fontSize = 12
        labelNode.fontName! += "-Bold"

        let bgNode = SKShapeNode(rect: CGRect(x: -15, y: -12, width: 15, height: 12))
        bgNode.fillColor = .accent
        bgNode.strokeColor = .clear

        addChild(bgNode)
        addChild(labelNode)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
