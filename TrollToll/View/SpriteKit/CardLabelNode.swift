//
//  CardLabelNode.swift
//  TrollToll
//
//  Created by Cagatay on 17.01.2026.
//

import SpriteKit

class CardLabelNode: SKLabelNode {
    init(text: String) {
        super.init()

        self.text = text
        horizontalAlignmentMode = .right
        verticalAlignmentMode = .top
        fontSize = 12
        fontName! += "-Bold"
        fontColor = .black
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
