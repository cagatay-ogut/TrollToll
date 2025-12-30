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
        case gameLobby(isHost: Bool)
    }

    var navPath = NavigationPath()

    func navigate(to destination: Destination) {
        navPath.append(destination)
    }
}
