//
//  PlayersTokensNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class PlayerTokensNode: TokensNode {
    func updateTokens(newTokenCount: Int, movePos: CGPoint) {
        guard newTokenCount != tokenCount else { return }

        let shownTokens = min(maxShownTokenNo, newTokenCount)
        if tokenCount > newTokenCount { // if token is removed
            removeTopToken(movePos: movePos)
        } else {
            while tokenNodes.count < shownTokens {
                appendToken()
            }
        }
        tokenCount = newTokenCount
        run(SKAction.wait(forDuration: GameScene.animDuration)) {
            self.updateCountLabel()
        }
    }
}
