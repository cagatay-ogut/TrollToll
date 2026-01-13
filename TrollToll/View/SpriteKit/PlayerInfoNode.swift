//
//  PlayerInfoNode.swift
//  TrollToll
//
//  Created by Cagatay on 13.01.2026.
//

import SpriteKit

class PlayerInfoNode: SKLabelNode {
    var playerName: String
    var point: Int

    init(playerName: String, point: Int, position: CGPoint, screenCenter: CGPoint) {
        self.playerName = playerName
        self.point = point
        super.init()
        self.position = position

        let text = "\(playerName)\npoints: \(point)"
        let nameNode = SKLabelNode(text: "\(text)")
        nameNode.numberOfLines = 2
        nameNode.horizontalAlignmentMode = .center
        nameNode.verticalAlignmentMode = .center
        nameNode.fontSize = 20
        nameNode.fontName! += "-Bold"

        nameNode.position = CGPoint(x: 0, y: -40)

        addChild(nameNode)

        if position.x < screenCenter.x - 1 {
            zRotation = -.pi / 2
        } else if position.x > screenCenter.x + 1 {
            zRotation = .pi / 2
        } else if position.y > screenCenter.y + 1 {
            zRotation = .pi
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
