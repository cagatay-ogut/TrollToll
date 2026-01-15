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
}
