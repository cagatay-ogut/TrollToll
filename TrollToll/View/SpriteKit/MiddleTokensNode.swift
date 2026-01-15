//
//  PlayersTokensNode.swift
//  TrollToll
//
//  Created by Cagatay on 7.01.2026.
//

import SpriteKit

class MiddleTokensNode: TokensNode {
    func updateTokens(newTokenCount: Int, movePos: CGPoint?) {
        guard newTokenCount != tokenCount else { return }

        let shownTokens = min(maxShownTokenNo, newTokenCount)
        if tokenCount > newTokenCount { // if token is removed
            while tokenNodes.count > shownTokens {
                removeTopToken(movePos: movePos)
            }
        } else if newTokenCount <= maxShownTokenNo {
            insertToken()
        }
        tokenCount = newTokenCount
        run(SKAction.wait(forDuration: 0.6)) {
            self.updateCountLabel()
        }
    }
}
