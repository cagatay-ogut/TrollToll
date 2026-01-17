//
//  CardNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class MiddleCardNode: SKSpriteNode {
    private var cardNode: SKSpriteNode
    private var labelNode: SKLabelNode

    private var cardNumber: Int {
        didSet {
            labelNode.text = "\(cardNumber)"
        }
    }

    init(cardNumber: Int, position: CGPoint, size: CGSize) {
        self.cardNumber = cardNumber
        self.labelNode = CardLabelNode(text: "\(cardNumber)")
        self.cardNode = SKSpriteNode(imageNamed: "card")
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = position

        cardNode.size = size
        labelNode.position = .init(x: size.width / 2, y: size.height / 2)

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

        let (rotation, cardPosition) = SceneCoordination
            .rotationAndPositionOfCard(for: lastPlayerPos, basedOn: scene!.size.center, offset: size.inPoint)
        let moveAction = SKAction.move(to: cardPosition, duration: GameScene.animDuration)
        let rotateAction = SKAction.rotate(byAngle: rotation, duration: GameScene.animDuration)

        // move old card to last player position, then set new card in original position
        let initialPos = position
        self.run(SKAction.group([moveAction, rotateAction])) {
            if cardNumber == 0 {
                self.removeAllChildren()
            } else {
                self.cardNumber = cardNumber
                self.position = initialPos
                self.zRotation = 0
            }
        }
    }
}
