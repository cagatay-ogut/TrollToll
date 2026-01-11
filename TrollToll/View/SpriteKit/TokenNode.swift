//
//  TokenNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class TokenNode: SKSpriteNode {
    var tokenCount: Int {
        didSet {
            children.compactMap { $0 as? SKLabelNode }.first?.text = "\(tokenCount)"
        }
    }

    init(tokenCount: Int, position: CGPoint, radius: CGFloat) {
        self.tokenCount = tokenCount
        super.init(texture: nil, color: UIColor.clear, size: CGSize(width: radius * 2, height: radius * 2))
        self.position = position

        let shownTokens = min(5, tokenCount)

        for index in 0..<shownTokens {
            let xPos = CGFloat(index * 2)
            let circleNode = SKShapeNode(circleOfRadius: radius)
            circleNode.strokeColor = .black
            circleNode.fillColor = .orange
            circleNode.position = .init(x: xPos, y: 0)

            if tokenCount > 5, index == shownTokens - 1 {
                let labelNode = SKLabelNode(text: "\(tokenCount)")
                labelNode.horizontalAlignmentMode = .center
                labelNode.verticalAlignmentMode = .center
                labelNode.fontSize = 10
                labelNode.fontName! += "-Bold"

                circleNode.addChild(labelNode)
            }
            self.addChild(circleNode)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
