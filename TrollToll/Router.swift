//
//  Router.swift
//  TrollToll
//
//  Created by Cagatay on 30.12.2025.
//

import SwiftUI

@Observable
class Router {
    enum Destination: Hashable {
        case lobby(user: User)
        case game(user: User, match: Match, gameState: GameState)
    }

    var navPath = NavigationPath()

    func navigate(to destination: Destination) {
        navPath.append(destination)
    }

    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}
