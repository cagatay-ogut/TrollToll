//
//  Authenticator.swift
//  TrollToll
//
//  Created by Cagatay on 1.01.2026.
//

protocol Authenticator {
    func authenticate() async -> AuthenticationState
}

enum AuthenticationState {
    case unauthenticated, authenticated(userId: String), failed
}
