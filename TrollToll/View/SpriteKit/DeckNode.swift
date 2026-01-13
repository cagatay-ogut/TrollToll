//
//  DeckNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class DeckNode: SKSpriteNode {
    private let maxShownCardNo = 5
    private let screenCenter: CGPoint
    private var cardNodes: [SKShapeNode] = []
    private var labelNode: SKLabelNode?

    var cardCount: Int {
        didSet {
            updateCards(oldCount: oldValue)
        }
    }

    init(cardCount: Int, position: CGPoint, size: CGSize, screenCenter: CGPoint) {
        self.cardCount = cardCount
        self.screenCenter = screenCenter
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = position

        let shownCards = min(maxShownCardNo, cardCount)

        for index in 0..<shownCards {
            let cardNode = createCardNode(at: index)

            if cardCount > maxShownCardNo, index == shownCards - 1 {
                createLabelNode()
                cardNode.addChild(labelNode!)
            }
            self.addChild(cardNode)
            cardNodes.append(cardNode)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func calculatePosition(for index: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(index * 2),
            y: CGFloat(index * 2)
        )
    }

    private func createCardNode(at index: Int) -> SKShapeNode {
        let position = calculatePosition(for: index)
        let cardNode = SKShapeNode(rectOf: size)
        cardNode.fillColor = .brown
        cardNode.strokeColor = .black
        cardNode.position = position
        cardNode.zPosition = CGFloat(index)
        return cardNode
    }

    private func createLabelNode() {
        labelNode = SKLabelNode(text: "\(cardCount)")
        labelNode!.horizontalAlignmentMode = .right
        labelNode!.verticalAlignmentMode = .top
        labelNode!.position = CGPoint(x: size.width / 2, y: size.height / 2)
        labelNode!.fontSize = 10
        labelNode!.fontName! += "-Bold"
    }

    private func updateLabelNode() {
        labelNode?.text = "\(cardCount)"
    }

    private func updateCards(oldCount: Int) {
        if oldCount > cardCount {
            if cardCount < maxShownCardNo {
                removeLabel()
            } else {
                insertCard()
            }
            removeTopCard()
        }
    }

    private func insertCard() {
        let cardNode = createCardNode(at: 0)
        self.addChild(cardNode)
        cardNodes.insert(cardNode, at: 0)

        let moveAction = SKAction.moveBy(x: 2, y: 2, duration: 0.2)
        for index in 1..<cardNodes.count {
            cardNodes[index].zPosition = CGFloat(index)
            cardNodes[index].run(moveAction)
        }
    }

    private func removeTopCard() {
        let topCardNode = cardNodes.last!
        if let labelNode {
            topCardNode.removeChildren(in: [labelNode])
            self.cardNodes.removeLast()
            self.cardNodes.last?.addChild(labelNode)
            self.updateLabelNode()
        }

        let removeAction = SKAction.move(to: convert(screenCenter, from: parent!), duration: 0.6)
        topCardNode.run(removeAction) {
            self.removeChildren(in: [topCardNode])
        }
    }

    private func removeLabel() {
        labelNode?.removeFromParent()
        labelNode = nil
    }
}
