//
//  PlayersTokensNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class TokensNode: SKSpriteNode {
    let maxShownTokenNo = 5
    let radius: CGFloat
    var tokenNodes: [SKShapeNode] = []
    var labelNode: SKLabelNode?

    var tokenCount: Int {
        didSet {
            labelNode?.text = "\(tokenCount)"
        }
    }

    init(tokenCount: Int, position: CGPoint, radius: CGFloat) {
        self.tokenCount = tokenCount
        self.radius = radius
        super.init(texture: nil, color: UIColor.clear, size: CGSize(width: radius * 2, height: radius * 2))
        self.position = position

        let shownTokens = min(maxShownTokenNo, tokenCount)
        for index in 0..<shownTokens {
            let tokenNode = createTokenNode(at: index)
            self.addChild(tokenNode)
            tokenNodes.append(tokenNode)
        }
        if tokenCount > maxShownTokenNo {
            self.labelNode = createLabelNode()
            tokenNodes.last?.addChild(labelNode!)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createTokenNode(at index: Int) -> SKShapeNode {
        let tokenNode = SKShapeNode(circleOfRadius: radius)
        tokenNode.strokeColor = .black
        tokenNode.fillColor = .orange
        tokenNode.position = .init(x: CGFloat(index * 2), y: 0)
        tokenNode.zPosition = CGFloat(index)
        return tokenNode
    }

    private func createLabelNode() -> SKLabelNode {
        let labelNode = SKLabelNode(text: "\(tokenCount)")
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.fontSize = 10
        labelNode.fontName! += "-Bold"
        return labelNode
    }

    func updateCountLabel() {
        if tokenCount <= maxShownTokenNo { // few tokens left, don't show count
            removeLabel()
        } else {
            createLabelOrUpdateLabelParent()
        }
    }

    private func removeLabel() {
        labelNode?.removeFromParent()
        labelNode = nil
    }

    private func createLabelOrUpdateLabelParent() {
        if let labelNode {
            labelNode.removeFromParent()
            self.tokenNodes.last?.addChild(labelNode)
        } else {
            self.labelNode = createLabelNode()
            self.tokenNodes.last?.addChild(labelNode!)
        }
    }

    func removeTopToken(movePos: CGPoint?) {
        let topTokenNode = tokenNodes.last!
        self.tokenNodes.removeLast()

        if let pos = movePos {
            let removeAction = SKAction.move(to: convert(pos, from: parent!), duration: 0.6)
            topTokenNode.run(removeAction) {
                self.removeChildren(in: [topTokenNode])
            }
        } else {
            self.removeChildren(in: [topTokenNode])
        }
    }

    func insertToken() {
        let tokenNode = createTokenNode(at: 0)
        self.addChild(tokenNode)
        tokenNodes.insert(tokenNode, at: 0)

        let moveAction = SKAction.moveBy(x: 2, y: 0, duration: 0.2)
        for index in 1..<tokenNodes.count {
            tokenNodes[index].zPosition = CGFloat(index)
            tokenNodes[index].run(moveAction)
        }
    }

    func appendToken() {
        let tokenNode = createTokenNode(at: tokenNodes.count)
        tokenNodes.append(tokenNode)
        self.addChild(tokenNode)
    }
}
