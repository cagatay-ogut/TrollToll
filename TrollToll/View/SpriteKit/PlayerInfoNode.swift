//
//  PlayerInfoNode.swift
//  TrollToll
//
//  Created by Cagatay on 13.01.2026.
//

import SpriteKit

class PlayerInfoNode: SKLabelNode {
    private let playerName: String
    private var labelNode: SKLabelNode?

    private var point: Int {
        didSet {
            labelNode?.text = "\(playerName)\npoints: \(point)"
        }
    }

    init(playerName: String, point: Int, position: CGPoint, screenCenter: CGPoint) {
        self.playerName = playerName
        self.point = point
        super.init()
        self.position = position

        let text = "\(playerName)\npoints: \(point)"
        labelNode = SKLabelNode(text: "\(text)")
        labelNode?.numberOfLines = 2
        labelNode?.horizontalAlignmentMode = .center
        labelNode?.verticalAlignmentMode = .center
        labelNode?.fontSize = 20
        labelNode?.fontName! += "-Bold"

        labelNode?.position = CGPoint(x: 0, y: -40)

        addChild(labelNode!)

        if position.x < screenCenter.x - 1 {
            zRotation = -.pi / 2
        } else if position.x > screenCenter.x + 1 {
            zRotation = .pi / 2
        } else if position.y > screenCenter.y + 1 {
            if position.x > screenCenter.x - 1, position.x < screenCenter.x + 1 {
                labelNode!.position = CGPoint(x: 0, y: 40)
            } else {
                zRotation = .pi
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePlayerPoint(newPoint: Int) {
        guard point != newPoint else { return }
        point = newPoint
    }
}
