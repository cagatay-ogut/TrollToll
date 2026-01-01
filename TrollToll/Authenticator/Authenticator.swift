//
//  Authenticator.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

protocol Authenticator {
    var authState: AuthenticationState { get }

    func authenticate() async
}

enum AuthenticationState {
    case unauthenticated, authenticated(userId: String), failed
}
