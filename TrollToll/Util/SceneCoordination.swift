//
//  PlayerCoordination.swift
//  TrollToll
//
//  Created by Cagatay on 15.01.2026.
//

import Foundation

enum SceneCoordination {
    static func rotationAndPositionOfCard(
        for playerPos: CGPoint,
        basedOn center: CGPoint,
        offset: CGPoint
    ) -> (rotation: CGFloat, position: CGPoint) {
        var rotation: CGFloat = 0
        var position = CGPoint(x: playerPos.x, y: playerPos.y + offset.y)
        if playerPos.x < center.x - 1 {
            rotation = -.pi / 2
            position = CGPoint(x: playerPos.x + offset.y, y: playerPos.y)
        } else if playerPos.x > center.x + 1 {
            rotation = .pi / 2
            position = CGPoint(x: playerPos.x - offset.y, y: playerPos.y)
        } else if playerPos.y > center.y + 1 {
            rotation = .pi
            position = CGPoint(x: playerPos.x, y: playerPos.y - offset.y)
        }
        return (rotation, position)
    }

    static func getScreenPosition(for position: CGPoint, basedOn center: CGPoint) -> ScreenPosition {
        if position.x < center.x - 1 {
            .left
        } else if position.x > center.x + 1 {
            .right
        } else if position.y > center.y + 1 {
            .top
        } else {
            .bottom
        }
    }
}

enum ScreenPosition {
    case left, right, top, bottom
}
