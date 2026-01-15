//
//  DeckNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class DeckNode: SKSpriteNode {
    private let maxShownCardNo = 5
    private var cardNodes: [SKShapeNode] = []
    private var labelNode: SKLabelNode?

    var cardCount: Int {
        didSet {
            if oldValue != cardCount {
                updateCards(oldCount: oldValue)
            }
        }
    }

    init(cardCount: Int, position: CGPoint, size: CGSize) {
        self.cardCount = cardCount
        super.init(texture: nil, color: UIColor.clear, size: size)
        self.position = position

        let shownCards = min(maxShownCardNo, cardCount)
        for index in 0..<shownCards {
            let cardNode = createCardNode(at: index)
            self.addChild(cardNode)
            cardNodes.append(cardNode)
        }
        if cardCount > maxShownCardNo {
            self.labelNode = createLabelNode()
            cardNodes.last?.addChild(labelNode!)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createCardNode(at index: Int) -> SKShapeNode {
        let cardNode = SKShapeNode(rectOf: size)
        cardNode.fillColor = .brown
        cardNode.strokeColor = .black
        cardNode.position = CGPoint(x: CGFloat(index * 2), y: CGFloat(index * 2))
        cardNode.zPosition = CGFloat(index)
        return cardNode
    }

    private func createLabelNode() -> SKLabelNode {
        let labelNode = SKLabelNode(text: "\(cardCount)")
        labelNode.horizontalAlignmentMode = .right
        labelNode.verticalAlignmentMode = .bottom
        labelNode.position = CGPoint(x: size.width / 2, y: -size.height / 2)
        labelNode.fontSize = 10
        labelNode.fontName! += "-Bold"
        return labelNode
    }

    // only update is card removal
    private func updateCards(oldCount: Int) {
        removeTopCard()
        if cardCount <= maxShownCardNo { // few cards left, don't show count anymore
            removeLabel()
        } else {
            insertCard()
            updateLabelParent()
            updateLabelNode()
        }
    }

    private func removeLabel() {
        labelNode?.removeFromParent()
        labelNode = nil
    }

    private func updateLabelNode() {
        labelNode?.text = "\(cardCount)"
    }

    private func updateLabelParent() {
        guard let labelNode else { return }
        labelNode.removeFromParent()
        cardNodes.last?.addChild(labelNode)
    }

    private func removeTopCard() {
        let topCardNode = cardNodes.last!
        self.cardNodes.removeLast()

        let removeAction = SKAction.move(to: convert(scene!.size.center, from: parent!), duration: 0.6)
        topCardNode.run(removeAction) {
            self.removeChildren(in: [topCardNode])
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
}
